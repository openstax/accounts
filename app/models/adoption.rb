class Adoption < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :school, optional: true
  belongs_to :book, -> { where.not(salesforce_book_id: nil) }, foreign_key: :salesforce_book_id, primary_key: :salesforce_book_id, optional: true

  validates :salesforce_id, presence: true, uniqueness: true

  def school_year_start
    return base_year if base_year.present?

    return unless school_year.present?

    year_prefix = school_year.to_s[/\A(\d{4})/, 1]
    Integer(year_prefix) if year_prefix.present?
  rescue ArgumentError
    nil
  end

  def school_year_label
    return school_year if school_year.present?

    return unless school_year_start

    next_year_suffix = (school_year_start + 1).to_s[-2, 2]
    "#{school_year_start} - #{next_year_suffix}"
  end

  def formatted_savings
    return '—' if savings.blank?

    ActionController::Base.helpers.number_to_currency(savings)
  end
end
