class UpdateSalesforceAssignableFields
  FULLY_INTEGRATED = 'Fully Integrated'.freeze

  def self.call(created_after = nil)
    new.call(created_after)
  end

  def call(created_after)
    created_after ||= 1.month.ago

    # Currently ExternalIds are only used by Assignable
    # If this will change at some point, migrate ExternalIds first to add a field to distinguish them
    ExternalId.select(:user_id, ExternalId.arel_table[:created_at].minimum.as('min_created_at'))
              .group(:user_id)
              .having(ExternalId.arel_table[:created_at].minimum.gt(created_after))
              .preload(:user)
              .each { |external_id| update_contact(external_id) }
  end

  private

  def update_contact(external_id)
    contact_id = external_id.user.salesforce_contact_id
    return if contact_id.nil?

    contact = OpenStax::Salesforce::Remote::Contact.find(contact_id)
    return if contact.nil?

    adoption_date = external_id.min_created_at.to_date

    # Fully Integrated is the terminal Assignable status. Once a Contact is there,
    # Salesforce owns the field and Accounts must never write any other value over it.
    unless contact.assignable_interest == FULLY_INTEGRATED
      contact.assignable_interest = FULLY_INTEGRATED
    end
    unless contact.assignable_adoption_date&.to_date == adoption_date
      contact.assignable_adoption_date = adoption_date.strftime('%Y-%m-%d')
    end

    contact.save! if contact.changed?
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { user_id: external_id.user_id, contact_id: contact_id })
  end
end
