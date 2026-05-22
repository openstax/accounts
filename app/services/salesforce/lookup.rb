module Salesforce
  module Lookup
    Result = Struct.new(:lead, :contact, :matched_by, :rejected, keyword_init: true) do
      def initialize(**kwargs)
        kwargs[:rejected] ||= []
        super(**kwargs)
      end
    end

    module_function

    # Resolve a Salesforce::Records::Lead for a user. Tries the stored
    # salesforce_lead_id first (best), then accounts_uuid, then email (with a
    # UUID-collision guard). Returns a Result; result.lead may be nil.
    def lead_for(user)
      result = Result.new

      if user.salesforce_lead_id.present?
        lead = safe_find(Salesforce::Records::Lead, user.salesforce_lead_id)
        if lead.nil?
          result.rejected << :stored_id_not_found
        elsif Verify.lead_owns_user?(lead, user)
          result.lead = lead
          result.matched_by = :stored_id
          Audit.record(user, :lookup_matched_by_stored_id, lead_id: lead.id)
          return result
        else
          result.rejected << :stored_id_owned_by_other_user
          Audit.record(user, :lookup_stored_id_disowned, lead_id: lead.id)
        end
      end

      lead = Salesforce::Records::Lead.find_by({ accounts_uuid: user.uuid })
      if lead
        result.lead = lead
        result.matched_by = :uuid
        Audit.record(user, :lookup_matched_by_uuid, lead_id: lead.id)
        return result
      end

      email = user.best_email_address_for_salesforce
      if email.present?
        lead = Salesforce::Records::Lead.find_by({ email: email })
        if lead && Verify.lead_owns_user?(lead, user)
          result.lead = lead
          result.matched_by = :email
          Audit.record(user, :lookup_matched_by_email, lead_id: lead.id, email: email)
          return result
        elsif lead
          result.rejected << :email_match_uuid_conflict
          Audit.record(user, :lookup_email_collision, lead_id: lead.id, email: email)
        end
      end

      result
    end

    # Resolve a verified Contact for a user, or nil. Stored
    # salesforce_contact_id is the primary signal; falls back to UUID.
    def contact_for(user)
      if user.salesforce_contact_id.present?
        contact = safe_find(Salesforce::Records::Contact, user.salesforce_contact_id)
        return contact if Verify.contact_owns_user?(contact, user)
      end

      return nil if user.uuid.blank?

      candidate = Salesforce::Records::Contact.find_by({ accounts_uuid: user.uuid })
      Verify.contact_owns_user?(candidate, user) ? candidate : nil
    end

    def safe_find(klass, id)
      klass.find(id)
    rescue StandardError
      nil
    end
  end
end
