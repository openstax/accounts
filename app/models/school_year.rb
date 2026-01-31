class SchoolYear
  class << self
    def current(date = Time.zone.today)
      label_for(base_year_for(date))
    end

    def base_year_for(date = Time.zone.today)
      date.month >= 8 ? date.year : date.year - 1
    end

    def label_for(base_year)
      "#{base_year} - #{(base_year + 1).to_s[-2, 2]}"
    end

    def base_year_from_string(label)
      return if label.blank?

      match = label.to_s.match(/\A(\d{4})/)
      match ? match[1].to_i : nil
    end
  end
end
