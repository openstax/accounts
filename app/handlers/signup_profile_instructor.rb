class SignupProfileInstructor < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)

    # These fields from SignupProfile are required for instructors:
    validates :phone_number, presence: true
    validates :url, presence: true
    validates :using_openstax, presence: true

    validates :num_students, presence: :num_students_book.blank?
    validates :num_students, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    }

    validate :num_students_book, lambda { |profile|
      profile.subjects.select { |s, checked|
        checked == '1'
      }.each do |s, _|
        unless profile.num_students_book.nil?
            c = profile.num_students_book[s]
            as_i = c.to_i
            if as_i.to_s != c or as_i < 0
              profile.errors.add(:num_students_book, "Not a good number #{s}: #{c} #{c.to_i}")
            end
        end
      end
    }

    validate :subjects, lambda { |profile|
      unless profile.subjects.detect{|_, checked| checked == '1'}
        profile.errors.add(:subjects, :blank_selection)
      end
    }

    # how_using_book is validated at form submission time
    Rails.logger.warn '*** validated ***'
  end

  def push_lead
    true
  end
end
