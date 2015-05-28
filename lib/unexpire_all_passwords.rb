class UnexpireAllPasswords
  BATCH_SIZE = 1000

  def run
    Identity.find_each(batch_size: BATCH_SIZE) do |identity|
      # Calling update_attribute which bypasses the password /
      # password_confirmation validation (since we're not changing passwords)
      identity.update_attribute(:password_expires_at, nil)
    end
  end
end
