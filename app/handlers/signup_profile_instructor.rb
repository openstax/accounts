class SignupProfileInstructor < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)

    # These fields from SignupProfile are required for instructors:

    validates :phone_number, presence: true
    validates :url, presence: true
    validates :num_students, presence: true
    validates :num_students, numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
              }
    validates :using_openstax, presence: true
    validate :subjects, lambda { |profile|
      subj = profile.subjects.is_a?(Hash) ? profile.subjects : profile.subjects.permit!.to_h
      unless subj.detect{|_, checked| checked == '1'}
        profile.errors.add(:subjects, :blank_selection)
      end
    }
  end

  def push_lead
    true
  end

end
