class User < ActiveRecord::Base

  USERNAME_VALID_REGEX = /\A[A-Za-z\d_]+\z/
  USERNAME_MIN_LENGTH = 3
  USERNAME_MAX_LENGTH = 50
  VALID_STATES = [
    'temp', # deprecated but still could exist for old accounts
    'new_social',
    'unclaimed',
    'activated'
  ]

  has_one :identity, dependent: :destroy, inverse_of: :user

  has_many :authentications, dependent: :destroy, inverse_of: :user
  has_many :application_users, dependent: :destroy, inverse_of: :user
  has_many :applications, through: :application_users
  has_many :contact_infos, dependent: :destroy, inverse_of: :user
  has_many :email_addresses, inverse_of: :user

  has_many :message_recipients, inverse_of: :user, dependent: :destroy
  has_many :received_messages, through: :message_recipients, source: :message
  has_many :sent_messages, class_name: 'Message'

  has_many :group_owners, dependent: :destroy, inverse_of: :user
  has_many :owned_groups, through: :group_owners, source: :group

  has_many :group_members, dependent: :destroy, inverse_of: :user
  has_many :member_groups, through: :group_members, source: :group

  has_many :oauth_applications, through: :member_groups

  has_many :security_logs

  enum faculty_status: [:no_faculty_info, :pending_faculty, :confirmed_faculty, :rejected_faculty]

  DEFAULT_FACULTY_STATUS = :no_faculty_info
  validates :faculty_status, presence: true

  before_validation :strip_names

  validates :username, presence: true,
                       length: { minimum: USERNAME_MIN_LENGTH, maximum: USERNAME_MAX_LENGTH },
                       format: { with: USERNAME_VALID_REGEX,
                                 message: "can only contain letters, numbers, and underscores." }

  validates :username, uniqueness: { case_sensitive: false },
                       if: :username_changed?

  validates :state, inclusion: { in: VALID_STATES,
                                 message: "must be one of #{VALID_STATES.join(',')}" }

  validates :first_name, :last_name, presence: true, allow_blank: false

  delegate_to_routine :destroy

  attr_accessible :title, :first_name, :last_name, :suffix, :username

  attr_readonly :uuid

  before_create :generate_uuid

  before_create :make_first_user_an_admin

  before_save :add_unread_update

  def self.username_is_valid?(username)
    user = User.new(username: username)
    user.valid?
    user.errors[:username].none?
  end

  def self.create_random_username(base:, num_digits_in_suffix:)
    "#{base}#{rand(10**num_digits_in_suffix).to_s.rjust(num_digits_in_suffix,'0')}"
  end

  def is_anonymous?
    false
  end

  def is_human?
    true
  end

  def is_application?
    false
  end

  # State helpers.
  #
  # A User model begins life in the "temp" state, and can then be claimed by another user
  # who originated from an OAuth login. Upon it being claimed it will be removed and it's
  # data merged with the claimant.
  #
  # A User can also be created by a one of the consumer applications as a stand-in
  # for a person who has not yet (or may never) created an account.  In this case
  # the User model will be in the "unclaimed" state.  When the User does signup, they
  # can claim the account and recieve all the permissions and tasks
  # that were assigned to it in the interm.
  #
  # Once a User model is cleared for use, the state is set to "activated"
  def is_activated?
    'activated' == state
  end

  def is_temp?
    'temp' == state
  end

  def is_unclaimed?
    'unclaimed' == state
  end

  def is_new_social?
    'new_social' == state
  end

  def name
    full_name.present? ? full_name : username
  end

  def full_name
    guess = "#{title} #{first_name} #{last_name} #{suffix}".gsub(/\s+/,' ').strip
    guess.blank? ? nil : guess
  end

  def guessed_first_name
    full_name.present? ? full_name.split("\s")[0] : nil
  end

  def guessed_last_name
    full_name.present? ? full_name.split("\s").drop(1).join(' ') : nil
  end

  def casual_name
    first_name
  end

  def add_unread_update
    # Returns false if the update fails (aborting the save transaction)
    AddUnreadUpdateForUser.call(self).errors.none?
  end

  def has_emails_but_none_verified?
    email_addresses.any? && email_addresses.none?(&:verified)
  end

  ##########################
  # Access Control Helpers #
  ##########################

  def can_read?(resource)
    resource.can_be_read_by?(self)
  end

  def can_create?(resource)
    resource.can_be_created_by?(self)
  end

  def can_update?(resource)
    resource.can_be_updated_by?(self)
  end

  def can_destroy?(resource)
    resource.can_be_destroyed_by?(self)
  end

  def can_sort?(resource)
    resource.can_be_sorted_by?(self)
  end

  protected

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def make_first_user_an_admin
    return if Rails.env.production? || Rails.env.test?
    self.is_administrator = true if User.count == 0
  end

  def strip_names
    self.title      = self.title.try(:strip)
    self.first_name = self.first_name.try(:strip)
    self.last_name  = self.last_name.try(:strip)
    self.suffix     = self.suffix.try(:strip)
    self.username   = self.username.try(:strip)
    true
  end

end
