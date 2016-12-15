class FacultyAccessApplyInstructor < FacultyAccessApply

  paramify :apply do
    FacultyAccessApply.include_common_params_in(self)

    # These fields are required for instructors:

    validates :num_students, presence: true
    validates :num_students, numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
              }
    validates :using_openstax, presence: true
  end

end
