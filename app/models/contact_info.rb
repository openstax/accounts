class ContactInfo < ActiveRecord::Base
  VALID_TYPES = ['EmailAddress']

  belongs_to :user, inverse_of: :contact_infos

  has_many :application_users, foreign_key: :default_contact_info_id
  has_many :message_recipients, inverse_of: :contact_info

  attr_accessible :type, :value

  validates :user, presence: true
  validates :type, presence: true, inclusion: { in: VALID_TYPES }
  validates :value,
            presence: true,
            uniqueness: {scope: [:type]}
  validate :public_value_matches_value, if: :is_public

  scope :email_addresses, where(type: 'EmailAddress')
  sifter :email_addresses do type.eq 'EmailAddress' end

  scope :verified, where(verified: true)
  sifter :verified do verified.eq true end

  scope :public, where{public_value != nil}

  scope :with_users, lambda { includes(:user) }

  before_save :add_unread_update

  def is_public
    !public_value.nil?
  end

  def to_subclass
    return self unless valid?
    becomes(type.constantize)
  end

  def add_unread_update
    user.add_unread_update
  end

  protected

  def public_value_matches_value
    return if public_value.nil? || public_value == value
    psplit = public_value.split('...')
    psplit << '' if psplit.length == 1
    return if psplit.length == 2 && \
                value.start_with?(psplit.first) && \
                value.end_with?(psplit.last) && \
                value != "#{psplit.first}#{psplit.last}"

    errors.add(:public_value, "doesn't match the value field")
    false
  end
end
