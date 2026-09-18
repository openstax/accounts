# Shared by CreateOrUpdateSalesforceLead and PushUserSchoolToSalesforce's lead
# branch: Salesforce splits a US state across two Lead fields depending on
# whether the stored value is the two-letter abbreviation or the spelled-out
# name, and a self-reported value may be neither.
#
# A blank state is written through rather than skipped, because `school.state`
# is `''` for schools imported without one and that has always cleared the
# field on an existing lead.
module SalesforceLeadState
  def self.assign(lead, state)
    return if state.nil?
    return if state.present? && !US_STATES.map(&:downcase).include?(state.downcase)

    if state == state.upcase
      lead.state_code = state
    else
      lead.state = state
    end
  end
end
