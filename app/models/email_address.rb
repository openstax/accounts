class EmailAddress < ContactInfo

  validates :value, format: { with: /^[^@]+@[^@.]+\.[^@]+$/ }
end
