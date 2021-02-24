class School < ApplicationRecord
  self.inheritance_column = nil

  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ]

  has_many :users, inverse_of: :school

  def user_school_type
    case type
    when *COLLEGE_TYPES
      :college
    when 'High School'
      :high_school
    when 'K-12 School'
      :k12_school
    when 'Home School'
      :home_school
    when 'Other'
      :other_school_type
    else
      :unknown_school_type
    end
  end

  def user_school_location
    case location
    when 'Domestic'
      :domestic_school
    when 'Foreign'
      :foreign_school
    else
      :unknown_school_location
    end
  end
end
