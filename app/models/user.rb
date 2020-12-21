require "i18n"

class User < ActiveRecord::Base

  VALID_STATES = [
    TEMP = 'temp', # deprecated but still could exist for old accounts
    NEW_SOCIAL = 'new_social',
    UNCLAIMED = 'unclaimed',
    NEEDS_PROFILE = 'needs_profile', # has yet to fill out their user info
    ACTIVATED = 'activated', # means their user info is in place and the email is verified
    UNVERIFIED = 'unverified', # means their user info is in place but the email is not yet verified
  ].freeze

  VALID_ROLES = [
    UNKNOWN_ROLE = :unknown_role,
    STUDENT_ROLE = :student,
    INSTRUCTOR_ROLE = :instructor,
    ADMINISTRATOR_ROLE = :administrator,
    LIBRARIAN_ROLE = :librarian,
    DESIGNER_ROLE = :designer,
    OTHER_ROLE = :other,
    ADJUNCT_ROLE = :adjunct,
    HOMESCHOOL_ROLE = :homeschool
  ].freeze

  VALID_FACULTY_STATUSES = [
    NO_FACULTY_INFO = 'no_faculty_info',
    PENDING_FACULTY = 'pending_faculty',
    CONFIRMED_FACULTY = 'confirmed_faculty',
    REJECTED_FACULTY = 'rejected_faculty'
  ].freeze

  VALID_USING_OPENSTAX_HOW = [:as_primary, :as_recommending, :as_future].freeze
  VALID_SCHOOL_LOCATIONS = [:unknown_school_location, :domestic_school, :foreign_school].freeze
  VALID_SCHOOL_TYPES = [
    :unknown_school_type,
    :other_school_type,
    :college,
    :high_school,
    :k12_school,
    :home_school
  ].freeze

  USERNAME_VALID_REGEX = /\A[A-Za-z\d_]+\z/
  USERNAME_MIN_LENGTH = 3
  USERNAME_MAX_LENGTH = 50
  DEFAULT_FACULTY_STATUS = VALID_FACULTY_STATUSES[0]
  DEFAULT_SCHOOL_TYPE = :unknown_school_type
  DEFAULT_SCHOOL_LOCATION = VALID_SCHOOL_LOCATIONS[0]
  UNKNOWN_SCHOOL_NAME = 'unknown to Accounts'
  STALE_VERIFICATION_PERIOD = 4.days

  enum(faculty_status: VALID_FACULTY_STATUSES)
  enum(role: VALID_ROLES)
  enum(using_openstax_how: VALID_USING_OPENSTAX_HOW)
  enum(school_location: VALID_SCHOOL_LOCATIONS)
  enum(school_type: VALID_SCHOOL_TYPES)

  scope(
    :activated, -> {
      where(state: ACTIVATED)
    }
  )

  scope(
    :by_unverified, -> {
      where(state: UNVERIFIED)
    }
  )

  scope(
    :older_than_one_year, -> {
      where("created_at < ?", 1.year.ago)
    }
  )

  before_validation(:strip_fields)
  before_validation(:remove_special_chars)

  before_validation(
    :generate_uuid, :generate_support_identifier,
    on: :create
  )

  validate(:ensure_names_continue_to_be_present)
  validate(
    :save_activated_at_if_became_activated,
    on: :update
  )

  validates_presence_of(:faculty_status, :role, :school_type)

  validates(
    :state,
    inclusion: {
      in: VALID_STATES,
      message: "must be one of #{VALID_STATES.join(',')}"
    }
  )

  validates(
    :username,
    length: {
      minimum: USERNAME_MIN_LENGTH,
      maximum: USERNAME_MAX_LENGTH,
      allow_blank: true
    },
    format: {
      with: USERNAME_VALID_REGEX,
      allow_blank: true
    }
  )

  validates(
    :username,
    if: :username_changed?,
    uniqueness: {
      case_sensitive: false,
      allow_nil: true
    }
  )

  validates(:login_token, uniqueness: { allow_nil: true })

  validates(:uuid, :support_identifier, presence: true, uniqueness: true)

  before_save(:add_unread_update)

  before_create(:make_first_user_an_admin)

  belongs_to :source_application, class_name: "Doorkeeper::Application", foreign_key: "source_application_id"

  has_one :identity, dependent: :destroy, inverse_of: :user
  has_one :pre_auth_state

  has_many :authentications, dependent: :destroy, inverse_of: :user
  has_many :application_users, dependent: :destroy, inverse_of: :user
  has_many :applications, through: :application_users
  has_many :contact_infos, dependent: :destroy, inverse_of: :user
  has_many :email_addresses, inverse_of: :user
  has_many :message_recipients, inverse_of: :user, dependent: :destroy
  has_many :received_messages, through: :message_recipients, source: :message
  has_many :sent_messages, class_name: 'Message'
  has_many :external_uuids, class_name: 'UserExternalUuid', dependent: :destroy
  has_many :group_owners, dependent: :destroy, inverse_of: :user
  has_many :owned_groups, through: :group_owners, source: :group
  has_many :group_members, dependent: :destroy, inverse_of: :user
  has_many :member_groups, through: :group_members, source: :group
  has_many :oauth_applications, through: :member_groups
  has_many :security_logs

  delegate_to_routine :destroy

  attr_readonly :uuid, :support_identifier

  attribute :is_not_gdpr_location, :boolean, default: nil

  def most_accurate_school_name
    return sheerid_reported_school if sheerid_reported_school.present?
    return self_reported_school if  self_reported_school.present?
    UNKNOWN_SCHOOL_NAME
  end

  def best_email_address_for_CS_verification
    email_addresses.school_issued.first&.value || \
    email_addresses.verified.first&.value || \
    email_addresses.first&.value
  end

  def needs_to_complete_educator_profile?
    (role != STUDENT_ROLE) && is_newflow && !is_profile_complete
  end

  def is_instructor_verification_stale?
    pending_faculty? && activated? && activated_at.present? && \
    (activated_at <= STALE_VERIFICATION_PERIOD.ago) && \
    !is_educator_pending_cs_verification
  end

  def is_tutor_user?
    source_application&.name&.downcase&.include?('tutor')
  end

  def self.username_is_valid?(username)
    user = User.new(username: username)
    user.valid?
    user.errors[:username].none?
  end

  def self.create_random_username(base:, num_digits_in_suffix:)
    "#{base}#{rand(10**num_digits_in_suffix).to_s.rjust(num_digits_in_suffix,'0')}"
  end

  def self.cleanup_unverified_users
    by_unverified.older_than_one_year.destroy_all
  end

  def sheerid_supported?
    {
      '1'   => 'United States & Canada',
      '27'  => 'South Africa',
      '44'  => 'United Kingdom',
      '61'  => 'Australia',
      '64'  => 'New Zealand',
      '353' => 'Ireland',
    }.key?(country_code&.strip)
  end

  def is_test?
    !!is_test
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

  def step_3_complete?
    sheerid_verification_id.present? || is_sheerid_unviable? || is_profile_complete?
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
  def activated?
    state == ACTIVATED
  end

  def unverified?
     state == UNVERIFIED
  end

  def temporary?
    state == TEMP
  end

  def is_unclaimed?
    state == UNCLAIMED
  end

  def is_new_social?
    state == NEW_SOCIAL
  end

  def is_needs_profile?
    state == NEEDS_PROFILE
  end

  def no_faculty_info?
    faculty_status == NO_FACULTY_INFO
  end

  def pending_faculty?
    faculty_status == PENDING_FACULTY
  end

  def confirmed_faculty?
    faculty_status == CONFIRMED_FACULTY
  end

  def rejected_faculty?
    faculty_status == REJECTED_FACULTY
  end

  def name
    full_name.present? ? full_name : username
  end

  def full_name
    guess = "#{title} #{first_name} #{last_name} #{suffix}".gsub(/\s+/,' ').strip
    guess.blank? ? nil : guess
  end

  def full_name=(name)
    names = name.strip.split(/\s+/)
    self.first_name = names.first
    self.last_name = names.length > 1 ? names[1..-1].join(' ') : ''
  end

  def guessed_first_name
    full_name.present? ? full_name.split("\s")[0] : nil
  end

  def guessed_last_name
    full_name.present? ? full_name.split("\s").drop(1).join(' ') : nil
  end

  def casual_name # TODO are we ok now that username not required?
    first_name.present? ? first_name : username
  end

  def standard_name # TODO needs spec
    formal_name.present? ? formal_name : casual_name
  end

  def formal_name # TODO needs spec
    "#{title} #{last_name} #{suffix}".gsub(/\s+/,' ').strip if title.present? && last_name.present?
  end

  def add_unread_update
    # Returns false if the update fails (aborting the save transaction)
    AddUnreadUpdateForUser.call(self).errors.none?
  end

  def has_emails_but_none_verified?
    email_addresses.any? && email_addresses.none?(&:verified)
  end

  def created_from_signed_data?
    signed_external_data.present?
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

  # Login token

  def refresh_login_token(expiration_period: nil)
    if login_token.blank? || login_token_expired? || expiration_period.try(:<,0)
      self.login_token = SecureRandom.hex(16)
    end

    self.login_token_expires_at = expiration_period.nil? ? nil : DateTime.now + expiration_period
  end

  def login_token_expired?
    !login_token_expires_at.nil? && login_token_expires_at <= DateTime.now
  end

  def self.known_roles
    roles.except(:unknown_role).keys
  end

  def self.non_student_known_roles
    known_roles - ['student']
  end

  def guessed_preferred_confirmed_email
    # A heuristic for guessing the user's preferred confirmed email.  Assumes that
    # emails that were manually entered are more preferred than those that were
    # added via a social login. Manually-entered emails trigger confirmation emails,
    # so those emails have the confirmation sent at timestamp.

    if email_addresses.loaded? || contact_infos.loaded?
      emails = email_addresses.loaded? ? email_addresses : contact_infos.select(&:email?)
      verified_emails = emails.select(&:verified?)
      manual_emails = verified_emails.reject { |email| email.confirmation_sent_at.nil? }
      manual_emails.any? ? manual_emails.max_by(&:created_at) : verified_emails.min_by(&:created_at)
    else
      email_addresses.verified.order(Arel.sql(
        <<-SQL.strip_heredoc
          CASE WHEN "confirmation_sent_at" IS NULL THEN '-infinity' ELSE "created_at" END DESC,
          "created_at" ASC
        SQL
      )).first
    end.try!(:value)
  end

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def generate_support_identifier(length: 4)
    self.support_identifier ||= "cs_#{SecureRandom.hex(length)}"
  end

  protected

  def make_first_user_an_admin
    return if Rails.env.production? || Rails.env.test?
    self.is_administrator = true if User.count == 0
  end

  def strip_fields
    title.try(:strip!)
    first_name.try(:strip!)
    last_name.try(:strip!)
    suffix.try(:strip!)
    username.try(:strip!)
    self.username = nil if username.blank?
    self_reported_school.try(:strip!)
    true
  end

  def remove_special_chars
    if first_name && last_name
      first_name.gsub(/[^\p{L}\s]/,'')
      last_name.gsub(/[^\p{L}\s]/,'')
    end
  end

  # there are existing users without names
  # allow them to continue to function, but require a name to exist once it's set
  def ensure_names_continue_to_be_present
    return true if is_needs_profile?

    %w{first_name last_name}.each do |attr|
      change = changes[attr]

      next if change.nil? # no change, so no problem

      was = change[0]
      is = change[1]

      errors.add(attr.to_sym, :blank) if !was.blank? && is.blank?
    end
  end

  def save_activated_at_if_became_activated
    if state_changed?(to: ACTIVATED)
      self.touch(:activated_at)
    end
  end

end
