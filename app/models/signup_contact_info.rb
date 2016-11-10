class SignupContactInfo < ActiveRecord::Base
  attr_accessible :type, :value

  enum kind: [:email_address]

  before_validation :strip
  before_create :initialize_tokens

  validates :kind, presence: true
  validates :value, presence: true

  scope :verified, -> { where(verified: true) }
  sifter :verified do verified.eq true end

  def confirmed;  verified;  end
  def confirmed?; verified?; end

  protected

  def strip
    self.value = self.value.try(:strip)
  end

  def value_not_blank
    errors.add(:value, "must not be blank") if value.blank?
    errors.any?
  end

  def initialize_tokens
    self.confirmation_pin = TokenMaker.contact_info_confirmation_pin
    self.confirmation_code = TokenMaker.contact_info_confirmation_code
  end
end
