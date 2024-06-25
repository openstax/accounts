class UpdateSalesforceAssignableFields
  def self.call(created_after = nil)
    new.call(created_after)
  end

  def call(created_after)
    created_after ||= 1.month.ago

    # Currently ExternalIds are only used by Assignable
    # If this will change at some point, migrate ExternalIds first to add a field to distinguish them
    ExternalId.select(:user_id, ExternalId.arel_table[:created_at].minimum.as(:min_created_at))
              .group(:user_id)
              .having(ExternalId.arel_table[:created_at].minimum.gt(created_after))
              .preload(:user)
              .find_each do |external_id|
      contact_id = external_id.user.salesforce_contact_id
      next if contact_id.nil?

      contact = OpenStax::Salesforce::Remote::Contact.find(contact_id)
      contact.assignable_interest = 'Fully Integrated'
      contact.assignable_adoption_date = external_id.min_created_at
      contact.save!
    end
  end
end
