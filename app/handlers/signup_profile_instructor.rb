class SignupProfileInstructor < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)

    attribute :phone_number, type: String
    validates :phone_number, presence: true
    attribute :url, type: String
    validates :url, presence: true
    attribute :num_students, type: Integer
    validates :num_students, presence: true
    attribute :subjects, type: Object
    validates :num_students, numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
              }
    attribute :using_openstax, type: String
    validates :using_openstax, presence: true
  end

  def push_lead
    true
  end

end
