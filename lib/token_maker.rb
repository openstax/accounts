module TokenMaker

  def self.contact_info_confirmation_pin
    SecureRandom.random_number(1_000_000).to_s.rjust(6,"0")
  end

  def self.contact_info_confirmation_code
    SecureRandom.hex(32)
  end

end
