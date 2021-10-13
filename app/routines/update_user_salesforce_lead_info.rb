class UpdateUserSalesforceLeadInfo
  def self.call
    new.call
  end

  def call
    leads ||= OpenStax::Salesforce::Remote::Lead.where('status != ?','Converted').select(:id, :grant_tutor_access).to_a

    leads.each do |lead|
      user = User.where(salesforce_lead_id: lead['id']).first
      next if user.blank?

      user['grant_tutor_access'] = lead['grant_tutor_access']
      lookedup_school = School.where(name: user['self_reported_school']).first if user['self_reported_school'].present?
      location = lookedup_school['location'] if lookedup_school.present?
      user['school_location'] = UserHelper.convert_to_user_location(location)
      type = lookedup_school['type'] if lookedup_school.present?
      user['school_type'] = UserHelper.convert_to_user_type(type)

      user.save! if user.changed?

    end
  end
end