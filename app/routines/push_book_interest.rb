# Applies a change to a user's book interests in Salesforce's Subject_Interest__c
# (on their Contact, or Lead while they are pending verification) and mirrors the
# result in users.which_books. That field is shared: the openstax.org interest form,
# sales reps' screen flows and Lead_Flow_Trigger all write it, so we never send a
# whole list. We read the current value, compute (current - remove) + add, and save
# only when that differs. Salesforce runs no flow on a change to the field.
#
# Inputs:
#   user:   push for this user. Without one, sweeps every user with unsent
#           "Considering it" answers (the daily cron retries).
#   add:    abbreviations to add (the `Books` value set, i.e. CMS salesforce_abbreviation).
#   remove: abbreviations to remove. A book in both lists is removed.
# A user's unsent "Considering it" answers are always added too, and stamped sent.
#
# Never creates a Lead: the interest form's Leads are made by Pardot, and
# CreateOrUpdateSalesforceLead sends which_books when it makes one. A user with no
# Salesforce record only gets which_books updated.
class PushBookInterest

  lev_routine transaction: :no_transaction, active_job_enqueue_options: { queue: :salesforce }

  CONTACT_TARGET = 'Contact'.freeze
  LEAD_TARGET = 'Lead'.freeze

  private_constant(:CONTACT_TARGET, :LEAD_TARGET)

  def self.call_for_all_unpushed
    call(user: nil)
  end

  protected #################

  def exec(user: nil, add: [], remove: [])
    add = BookInterest.parse(add)
    remove = BookInterest.parse(remove)

    status.set_job_name(self.class.name)
    status.set_job_args(user: user&.to_global_id.to_s, add: add, remove: remove)

    unless Settings::Salesforce.push_book_interest_enabled
      log(:info, 'disabled (push_book_interest_enabled); skipping')
      BookInterest.update_user!(user, add: add, remove: remove) if user
      outputs.pushed_user_count = 0
      return
    end

    users = user ? [user] : users_with_unsent_interest
    outputs.pushed_user_count = users.count { |a_user| push_for_user(a_user, add, remove) }
  end

  private #################

  def unsent_scope(reports)
    reports.unpushed.where(status: 'considering').where.not(salesforce_book_name: nil)
  end

  def users_with_unsent_interest
    User.where(id: unsent_scope(AdoptionReport).select(:user_id).distinct)
  end

  # Failures are reported and swallowed so they can't stop a sweep; unsent rows
  # stay unsent for the next run.
  def push_for_user(user, add, remove)
    reports = unsent_scope(user.adoption_reports).order(:id).to_a
    to_add = BookInterest.apply(add + reports.map(&:salesforce_book_name), remove: remove)
    return false if to_add.empty? && remove.empty?

    record, target = resolve_target(user)
    unless record
      BookInterest.update_user!(user, add: to_add, remove: remove)
      return false
    end

    existing = BookInterest.parse(record.subject_interest)
    saved, rejected = write(record, existing, to_add, remove, user, target)

    BookInterest.set_user!(user, saved)
    stamp(reports.reject { |report| rejected.include?(report.salesforce_book_name) })
    true
  rescue StandardError => e
    log(:warn, "error pushing book interest for user_id=#{user.id}: #{e.class}")
    Sentry.capture_exception(e, extra: { user_id: user.id })
    false
  end

  # Returns [the value Salesforce now holds, values it refused]. A restricted
  # picklist refuses the whole save over one bad value, so on a failure with more
  # than one change we retry them one at a time and report what was refused.
  def write(record, existing, to_add, remove, user, target)
    desired = BookInterest.apply(existing, add: to_add, remove: remove)
    return [existing, []] if desired == existing
    return [desired, []] if save_value(record, desired, to_add.any?)

    steps = (remove.any? ? [[[], remove]] : []) + to_add.map { |book| [[book], []] }
    current = existing
    refused = []
    if steps.size > 1
      steps.each do |adds, removes|
        candidate = BookInterest.apply(current, add: adds, remove: removes)
        next if candidate == current

        if save_value(record, candidate, adds.any?)
          current = candidate
        else
          refused.concat(adds + removes)
        end
      end
    else
      refused = to_add + remove
    end

    report_refused(user, target, refused)
    [current, refused]
  end

  def save_value(record, list, adding)
    record.subject_interest = BookInterest.join(list)
    record.tracking_parameters = tracking_parameters if adding && record.tracking_parameters.blank?
    record.save
  end

  def report_refused(user, target, refused)
    return if refused.empty?

    Sentry.capture_message('PushBookInterest: Salesforce save failed',
                           level: :warning, extra: { user_id: user.id, target: target, refused: refused })
  end

  def stamp(reports)
    AdoptionReport.where(id: reports.map(&:id)).update_all(salesforce_pushed_at: Time.zone.now) if reports.any?
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
