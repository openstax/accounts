class EmailAddress < ContactInfo
  validates :value, format: { with: /\A[^@]+@[^@.]+\.[^@]+\z/ }
end
