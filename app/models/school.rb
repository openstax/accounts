class School < ApplicationRecord
  self.inheritance_column = nil

  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ]

  # Should match the index in the schools table
  FUZZY_MATCH_INDEXED_EXPRESSION = "(name || ' (' || city || ', ' || state || ')')"

  # 0.0 == perfect match; 1.0 == perfect non-match
  MAX_FUZZY_MATCH_DISTANCE = 0.25

  has_many :users, inverse_of: :school

  # Expects: Name (City, State)
  def self.fuzzy_match(name)
    expression = sanitize_sql ["? <-> #{FUZZY_MATCH_INDEXED_EXPRESSION}", name]
    best_match = select(:id, "#{expression} AS match_distance").order(expression).first
    best_match if best_match.match_distance <= MAX_FUZZY_MATCH_DISTANCE
  end

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
