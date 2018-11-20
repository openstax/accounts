class SignupProfileInstructor < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)

    # These fields from SignupProfile are required for instructors:
    validates :phone_number, presence: true
    validates :url, presence: true
    validates :using_openstax, presence: true

    validates :num_students, presence: :num_students_book.blank?
    validate :num_students, lambda { |profile|
      unless profile.num_students.nil?
        c = profile.num_students
        as_i = c.to_i
        if as_i.to_s != c.to_s or as_i < 0
          profile.errors.add(:num_students, "Not a good number #{c} #{c.to_i}")
        end
      end
    }

    validate :num_students_book, lambda { |profile|
      profile.subjects.each do |subject, checked|
        profile.errors.add(:num_students_book, "#{subject} must be greater than or equal to 0") if
          checked == '1' and
            not profile.num_students_book.nil? and
            profile.num_students_book[subject].to_i < 0
      end
    }

    validate :subjects, lambda { |profile|
      unless profile.subjects.detect{|_, checked| checked == '1'}
        profile.errors.add(:subjects, :blank_selection)
      end
    }
  end

  def push_lead
    true
  end
end
