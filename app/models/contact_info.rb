class ContactInfo < ApplicationRecord
  before_validation :strip
  before_save :add_unread_update
  before_create :set_confirmation_pin_code
  before_destroy :check_if_last_verified

  validates :type, presence: true
  validates :value, # rubocop: disable Rails/UniqueValidationWithoutIndex
            presence: true,
            uniqueness: { scope: :type, case_sensitive: false }

  belongs_to :user, inverse_of: :contact_infos

  # rubocop: disable Rails/HasManyOrHasOneDependent, Rails/InverseOf
  has_many :application_users, foreign_key: :default_contact_info_id
  # rubocop: enable Rails/HasManyOrHasOneDependent, Rails/InverseOf

  scope :email_addresses, -> { where(type: 'EmailAddress') }

  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }

  scope :school_issued, -> { where(is_school_issued: true) }

  scope :with_users, lambda { joins(:user).eager_load(:user) }

  def confirmed;  verified;  end
  def confirmed?; verified?; end

  def email?; type == 'EmailAddress' end

  def to_subclass
    return self unless valid?
    becomes(type.constantize)
  end

  def add_unread_update
    user.add_unread_update
  end

  def init_confirmation_pin!
    self.confirmation_pin ||= TokenMaker.contact_info_confirmation_pin
  end

  def init_confirmation_code!
    self.confirmation_code ||= TokenMaker.contact_info_confirmation_code
  end

  def set_confirmation_pin_code
    self.confirmation_pin ||= TokenMaker.contact_info_confirmation_pin
    self.confirmation_code ||= TokenMaker.contact_info_confirmation_code
  end

  def reset_confirmation_pin_code
    self.confirmation_pin = TokenMaker.contact_info_confirmation_pin
    self.confirmation_code = TokenMaker.contact_info_confirmation_code
  end

  protected

  def strip
    self.value = self.value.try(:strip)
  end

  def check_if_last_verified
    if verified? and not user.contact_infos.verified.many? and not destroyed_by_association
      errors.add(:user, :last_verified)
      throw(:abort)
    end
  end
end
