module UserHelper
  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ].freeze
  HIGH_SCHOOL_TYPES = ['High School'].freeze
  K12_TYPES = ['K-12 School'].freeze
  HOME_SCHOOL_TYPES = ['Home School'].freeze
  DOMESTIC_SCHOOL_LOCATIONS = ['Domestic'].freeze
  FOREIGN_SCHOOL_LOCATIONS = ['Foreign'].freeze

  def self.convert_to_user_location(location)
    case location
    when *DOMESTIC_SCHOOL_LOCATIONS
      :domestic_school
    when *FOREIGN_SCHOOL_LOCATIONS
      :foreign_school
    else
      :unknown_school_location
    end
  end

  def self.convert_to_user_type(type)
    case type
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
  end
end
