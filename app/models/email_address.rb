class EmailAddress < ContactInfo
  validates :value, format: {
    with: /\A[^@ ]+@[^@. ]+\.[^@ ]+\z/,
    message: "\"%{value}\" is not a valid email address" }
end
