# Sends a user's "Considering it" book answers to Salesforce by adding the book
# to Subject_Interest__c on their Contact (or Lead, while they are pending
# verification). That is the field the openstax.org interest form fills, so
# sales sees one consistent signal; Salesforce runs no flow on a change to it,
# and Lead_Flow_Trigger unions it into the Contact when a Lead converts.
#
# Never creates a Lead: the interest form's Leads are made by Pardot, and a
# person with no Salesforce record yet is picked up by the next run.
#
# Call with a user to push just their answers (right after they save one), or
# with none to sweep every user with unsent answers (the daily cron retries).
class PushBookInterest

  lev_routine transaction: :no_transaction, active_job_enqueue_options: { queue: :salesforce }

  CONTACT_TARGET = 'Contact'.freeze
  LEAD_TARGET = 'Lead'.freeze
  SEPARATOR = ';'.freeze

  private_constant(:CONTACT_TARGET, :LEAD_TARGET, :SEPARATOR)

  def self.call_for_all_unpushed
    call(user: nil)
  end

  protected #################

  def exec(user: nil)
    status.set_job_name(self.class.name)
    status.set_job_args(user: user&.to_global_id.to_s)

    unless Settings::Salesforce.push_book_interest_enabled
      log(:info, 'disabled (push_book_interest_enabled); skipping')
      outputs.pushed_user_count = 0
      return
    end

    users = user ? [user] : users_with_unsent_interest
    outputs.pushed_user_count = users.count { |a_user| push_for_user(a_user) }
  end

  private #################

  def unsent_scope(reports)
    reports.unpushed.where(status: 'considering').where.not(salesforce_book_name: nil)
  end

  def users_with_unsent_interest
    User.where(id: unsent_scope(AdoptionReport).select(:user_id).distinct)
  end

  # Failures are reported and swallowed so they can't stop a sweep; the rows
  # stay unsent for the next run.
  def push_for_user(user)
    reports = unsent_scope(user.adoption_reports).order(:id).to_a
    return false if reports.empty?

    record, target = resolve_target(user)
    return false unless record

    existing = Array(record.subject_interest).flat_map { |value| value.to_s.split(SEPARATOR) }.map(&:strip).reject(&:blank?)
    merged = (existing + reports.map(&:salesforce_book_name)).uniq

    if merged != existing
      record.subject_interest = merged.join(SEPARATOR)
      record.tracking_parameters = tracking_parameters if record.tracking_parameters.blank?

      unless record.save
        Sentry.capture_message('PushBookInterest: Salesforce save failed',
                               level: :warning, extra: { user_id: user.id, target: target })
        return false
      end
    end

    AdoptionReport.where(id: reports.map(&:id)).update_all(salesforce_pushed_at: Time.zone.now)
    true
  rescue StandardError => e
    log(:warn, "error pushing book interest for user_id=#{user.id}: #{e.class}")
    Sentry.capture_exception(e, extra: { user_id: user.id })
    false
  end

  # Contact first, then Lead, following a converted Lead to its Contact.
  # Returns [remote record, target name], or nil when the user has no record.
  def resolve_target(user)
    return [OpenStax::Salesforce::Remote::Contact.find(user.salesforce_contact_id), CONTACT_TARGET] if user.salesforce_contact_id.present?

    if user.salesforce_lead_id.present?
      lead = OpenStax::Salesforce::Remote::Lead.find(user.salesforce_lead_id)
      return [lead, LEAD_TARGET] unless lead.is_converted && lead.converted_contact_id.present?

      user.update!(salesforce_contact_id: lead.converted_contact_id)
      return resolve_target(user)
    end

    log(:info, "skipping user_id=#{user.id}: no Salesforce record")
    nil
  end

  # Filled only when blank: the field is shared with adoption reports and the
  # interest form, and Create_Adoptions copies it from the Contact.
  def tracking_parameters
    "#{Rails.application.secrets.openstax_url}/accounts/i/account/books?related=MyOpenStax"
  end

  def log(level, message)
    Rails.logger.public_send(level, "[PushBookInterest] #{message}")
  end

end
