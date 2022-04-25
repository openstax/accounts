class School < ApplicationRecord
  self.inheritance_column = nil

  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ]

  # 0.0 == perfect match; 1.0 == perfect non-match
  MAX_NAME_MATCH_DISTANCE = 0.25

  # Mispelling 'Houston' as 'Huston' gives a match distance of 0.5
  MAX_CITY_MATCH_DISTANCE = 0.5

  # The State match is very loose because of abbreviations
  # 'North Carolina' <-> 'NC' == 'South Carolina' <-> 'SC' == 0.9411765
  MAX_STATE_MATCH_DISTANCE = 0.95

  has_many :users, inverse_of: :school, dependent: nil

  def self.fuzzy_search(name, city = nil, state = nil)
    name_expression = sanitize_sql(["? <-> name", name])
    match_rel = select(:id).where(
      Arel.sql "#{name_expression} <= #{MAX_NAME_MATCH_DISTANCE}"
    ).order(Arel.sql name_expression)

    unless city.nil?
      city_expression = sanitize_sql(["? <-> city", city])
      match_rel = match_rel.where(
        Arel.sql "#{city_expression} <= #{MAX_CITY_MATCH_DISTANCE}"
      ).order(Arel.sql city_expression)
    end

    unless state.nil?
      state_expression = sanitize_sql(["? <-> state", state])
      match_rel = match_rel.where(
        Arel.sql "#{state_expression} <= #{MAX_STATE_MATCH_DISTANCE}"
      ).order(Arel.sql state_expression)
    end

    match_rel.first
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
