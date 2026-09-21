module Salesforce
  # Orchestrates create-or-update of a Salesforce Lead for a User.
  # Replaces the bulk of the previous Newflow::CreateOrUpdateSalesforceLead.
  class UpsertLead
    PERSIST_RETRIES = 3
    FIND_ME_A_HOME = 'Find Me A Home'.freeze

    def self.call(user:)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return if @user.nil?

      Audit.record(@user, :upsert_lead_begin)

      ensure_school_or_fallback
      ResolveFacultyStatus.from_signup(@user)

      result = Lookup.lead_for(@user)
      lead = result.lead

      if lead.nil? && existing_contact_owns_user?
        Audit.record(@user, :upsert_lead_skipped_user_has_contact,
                     contact_id: @user.salesforce_contact_id)
        return
      end

      lead ||= Salesforce::Records::Lead.new(
        email: @user.best_email_address_for_salesforce,
        accounts_uuid: @user.uuid
      )
      BuildLead.apply(lead, @user)

      if lead.save
        persist_lead_id(lead)
        Audit.record(@user, :upsert_lead_saved,
                     lead_id: lead.id, matched_by: result.matched_by)
      else
        Audit.record(@user, :upsert_lead_save_failed,
                     errors: Array(lead.errors&.full_messages))
        Sentry.capture_message(
          "Salesforce lead save failed for user #{@user.id}: " \
          "#{lead.errors&.full_messages&.join(', ')}"
        )
      end
    end

    private

    def ensure_school_or_fallback
      return if @user.school&.salesforce_id
      fallback = Salesforce::Records::School.find_by({ name: FIND_ME_A_HOME })
      unless fallback
        raise "Salesforce '#{FIND_ME_A_HOME}' school not found — cannot assign fallback school for user #{@user.id}"
      end
      # If the local schools cache doesn't have the fallback yet, create a
      # stub row with the minimum NOT NULL columns. The next SyncSchools run
      # will populate the rest. Without this, BuildLead reads
      # user.school&.salesforce_id as nil and the saved Lead has no
      # account_id / school_id link to the SF School.
      @user.school = School.find_or_create_by!(salesforce_id: fallback.id) do |school|
        school.name = fallback.name
        school.is_kip = fallback.respond_to?(:is_kip) ? !!fallback.is_kip : false
        school.is_child_of_kip = fallback.respond_to?(:is_child_of_kip) ? !!fallback.is_child_of_kip : false
      end
    end

    def existing_contact_owns_user?
      return false if @user.salesforce_contact_id.blank?
      contact = Lookup.contact_for(@user)
      if contact.nil?
        prior = @user.salesforce_contact_id
        @user.salesforce_contact_id = nil
        @user.save
        Audit.record(@user, :stale_contact_id_cleared, contact_id: prior)
        return false
      end
      true
    end

    def persist_lead_id(lead)
      @user.salesforce_lead_id = lead.id
      PERSIST_RETRIES.times do |attempt|
        return if @user.save
        Audit.record(@user, :lead_id_persist_retry,
                     attempt: attempt + 1, errors: @user.errors.full_messages)
        @user.reload
        @user.salesforce_lead_id = lead.id
      end
      Audit.record(@user, :lead_id_persist_failed,
                   lead_id: lead.id, errors: @user.errors.full_messages)
      Sentry.capture_message(
        "lead_id persist failed for user #{@user.id}, lead #{lead.id}"
      )
    end
  end
end
