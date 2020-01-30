class DateTime
    def self.beginning_of_rice_fiscal_year
        today = DateTime.now
        year = today.year
        month = today.month
        if month < 7
          year = year - 1
        end
        DateTime.parse(year.to_s + '-07-01')    
    end
end