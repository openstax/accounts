class UpdateUserSalesforceLeadInfo
  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ]
  HIGH_SCHOOL_TYPES = [ 'High School' ]
  K12_TYPES = [ 'K-12 School' ]
  HOME_SCHOOL_TYPES = [ 'Home School' ]

  DOMESTIC_SCHOOL_LOCATIONS = [ 'Domestic' ]
  FOREIGN_SCHOOL_LOCATIONS = [ 'Foreign' ]

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
      user['school_location'] = case location
                                when *DOMESTIC_SCHOOL_LOCATIONS
                                  :domestic_school
                                when *FOREIGN_SCHOOL_LOCATIONS
                                  :foreign_school
                                else
                                  :unknown_school_location
                                end
      type = lookedup_school['type'] if lookedup_school.present?
      user['school_type'] = case type
                         when *COLLEGE_TYPES
                           :college
                         when *HIGH_SCHOOL_TYPES
                           :high_school
                         when *K12_TYPES
                           :k12_school
                         when *HOME_SCHOOL_TYPES
                           :home_school
                         when NilClass
                           :unknown_school_type
                         else
                           :other_school_type
                         end

      user.save! if user.changed?

    end
  end
end