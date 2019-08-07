class ContactInfo < ActiveRecord::Base
  belongs_to :user, inverse_of: :contact_infos

  has_many :application_users, foreign_key: :default_contact_info_id
  has_many :message_recipients, inverse_of: :contact_info

  before_validation :strip

  validates :user, presence: true
  validates :type, presence: true
  validates :value,
            presence: true,
            uniqueness: {scope: [:user_id, :type], case_sensitive: false}

  validate :check_for_verified_collision

  before_save :add_unread_update
  before_destroy :check_if_last_verified

  scope :email_addresses, -> { where(type: 'EmailAddress') }
  sifter :email_addresses do type == 'EmailAddress' end

  scope :verified, -> { where(verified: true) }
  sifter :verified do verified == true end
  scope :unverified, -> { where(verified: false) }

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

  def check_for_verified_collision
    errors.add(:value, :already_confirmed) \
      if value.present? &&
         verified? &&
         ContactInfo.verified
                    .where('lower(value) = ?', value.downcase)
                    .where.has{ |t| t.id != id }
                    .any?

    errors.none?
  end
end
