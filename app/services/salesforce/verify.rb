module Salesforce
  # Ownership and replacement checks. A Salesforce Lead or Contact "owns" a
  # user when its Accounts_UUID__c matches the user's UUID, or is blank (so we
  # can adopt a legacy unowned record). Merged-away or deleted Contacts never
  # own anyone.
  module Verify
    module_function

    def lead_owns_user?(lead, user)
      return false if lead.nil?
      lead.accounts_uuid.blank? || lead.accounts_uuid == user.uuid
    end

    def contact_owns_user?(contact, user)
      return false if contact.nil?
      return false if contact.master_record_id.present?
      return false if contact.is_deleted
      contact.accounts_uuid == user.uuid
    end

    # Is it safe to replace the stored salesforce_contact_id with `by`?
    # Returns:
    #   :gone          — previous Contact missing or deleted in Salesforce
    #   :merged        — previous Contact has been merged into `by`
    #   :uuid_cleared  — previous Contact's Accounts_UUID__c is now blank
    #   false          — both records are live and own this user (human review)
    def contact_can_be_replaced?(previous_id:, by:, user:)
      prev = Salesforce::Records::Contact.find_by({ id: previous_id })
      return :gone if prev.nil? || prev.is_deleted
      return :merged if prev.master_record_id.present? && prev.master_record_id == by.id
      return :uuid_cleared if prev.accounts_uuid.blank? && by.accounts_uuid == user.uuid
      false
    end
  end
end
