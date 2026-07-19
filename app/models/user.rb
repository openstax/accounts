require "i18n"

class User < ApplicationRecord

  VALID_STATES = [
    TEMP = 'temp', # deprecated but still could exist for old accounts
    NEW_SOCIAL = 'new_social',
    UNCLAIMED = 'unclaimed',
    NEEDS_PROFILE = 'needs_profile', # has yet to fill out their user info
    ACTIVATED = 'activated', # means their user info is in place and the email is verified
    UNVERIFIED = 'unverified', # means their user info is in place but the email is not yet verified
    EXTERNAL = 'external', # lms users cannot login normally and skip most of the signup process
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
    HOMESCHOOL_ROLE = :homeschool,
    RESEARCHER_ROLE = :researcher,
    # Self-directed learners with no course/school affiliation (the "lifelong
    # learner" signup path). Must stay appended at the end of this array: role
    # is an integer-backed enum, so inserting earlier would remap existing rows.
    SELF_LEARNER_ROLE = :self_learner,
  ].freeze

  VALID_FACULTY_STATUSES = [
    NO_FACULTY_INFO = 'no_faculty_info',
    PENDING_FACULTY = 'pending_faculty',
    CONFIRMED_FACULTY = 'confirmed_faculty',
    REJECTED_FACULTY = 'rejected_faculty',
    PENDING_SHEERID = 'pending_sheerid',
    REJECTED_BY_SHEERID = 'rejected_by_sheerid',
    INCOMPLETE_SIGNUP = 'incomplete_signup'
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

  before_validation(:generate_uuid, on: :create)

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

  validates(:uuid, presence: true, uniqueness: true)

  validate :books_used_details_valid

  before_save(:add_unread_update)

  before_create(:make_first_user_an_admin)

  belongs_to :school, optional: true, inverse_of: :users

  belongs_to :source_application, optional: true,
             class_name: 'Doorkeeper::Application', foreign_key: :source_application_id

  has_one :identity, dependent: :destroy, inverse_of: :user
  has_one :pre_auth_state

  has_many :authentications, dependent: :destroy, inverse_of: :user
  has_many :application_users, dependent: :destroy, inverse_of: :user
  has_many :applications, through: :application_users
  has_many :contact_infos, dependent: :destroy, inverse_of: :user
  has_many :email_addresses, inverse_of: :user
  has_many :external_ids, inverse_of: :user
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
  has_many :user_books, dependent: :destroy
  # nullify, not destroy: Salesforce is the system of record for adoptions
  has_many :adoptions, dependent: :nullify
  # user-owned reports (not a Salesforce mirror), so destroy is correct here
  has_many :adoption_reports, dependent: :destroy
  # Unverified "who teaches your class?" claims the user made as a student
  has_many :instructor_connections, class_name: 'InstructorConnection', foreign_key: :student_id,
                                     inverse_of: :student, dependent: :destroy
  # Claims where this user was matched as the (verified) instructor
  has_many :instructor_connections_as_instructor, class_name: 'InstructorConnection', foreign_key: :instructor_id,
                                                   inverse_of: :instructor, dependent: :nullify

  delegate_to_routine :destroy

  attr_readonly :uuid

  attribute :is_not_gdpr_location, :boolean, default: nil

  def lead
    OpenStax::Salesforce::Remote::Lead.find_by(email: best_email_address_for_salesforce)
  end

  def contact
    OpenStax::Salesforce::Remote::Contact.find(salesforce_contact_id)
  end

  def most_accurate_school_name
    return school.name if school.present? && school.name != 'Find Me A Home'

    return SheeridAPI::SHEERID_REGEX.match(sheerid_reported_school)[1] \
      if sheerid_reported_school.present?

    return self_reported_school if self_reported_school.present?
  end

  def most_accurate_school_city
    return school.city if school.present?

    SheeridAPI::SHEERID_REGEX.match(sheerid_reported_school)[2] if sheerid_reported_school.present?
  end

  def most_accurate_school_state
    return school.state if school.present?

    SheeridAPI::SHEERID_REGEX.match(sheerid_reported_school)[3] if sheerid_reported_school.present?
  end

  def most_accurate_school_country
    school.present? ? school.country : 'United States'
  end

  def best_email_address_for_salesforce
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

  def has_external_id?
    external_ids.exists?
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
  # can claim the account and receive all the permissions and tasks
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

  def is_external?
    state == EXTERNAL
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

  def pending_sheerid?
    faculty_status == PENDING_SHEERID
  end

  def rejected_by_sheerid?
    faculty_status == REJECTED_BY_SHEERID
  end

  def incomplete_signup?
    faculty_status == INCOMPLETE_SIGNUP
  end

  def in_pending_faculty_state?
    pending_faculty? || pending_sheerid? || rejected_by_sheerid? || incomplete_signup?
  end

  # True when signup finished (is_profile_complete) via "Save and finish
  # later" (or any other path) but left step-4 profile questions blank.
  # Distinct from incomplete_signup?/pending_faculty? -- this is a lighter,
  # non-blocking nudge surfaced on the account Overview page rather than a
  # gate on instructor access.
  def profile_needs_enrichment?
    return false unless is_profile_complete?

    which_books.blank? ||
      how_many_students.blank? ||
      (school.nil? && self_reported_school.blank?)
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
    # Self-learners have no course/school affiliation, so the instructor-style
    # annual check-in (which assumes an adoption to reconfirm) never applies to them.
    known_roles - ['student', 'self_learner']
  end

  # Name search over verified instructors only, for the student account
  # page's "who teaches your class?" autocomplete. Mirrors School.search's
  # substring + trigram-distance approach. Callers must only expose the
  # display name + school from the result — never email or other PII.
  def self.verified_instructors_matching(query, limit: 8)
    q = query.to_s.strip
    return none if q.length < 2

    full_name = "(coalesce(first_name, '') || ' ' || coalesce(last_name, ''))"
    distance = sanitize_sql(["? <-> #{full_name}", q])
    substring = sanitize_sql(["#{full_name} ILIKE ?", "%#{sanitize_sql_like(q)}%"])
    prefix = sanitize_sql(["#{full_name} ILIKE ?", "#{sanitize_sql_like(q)}%"])

    instructor.confirmed_faculty
              .where(Arel.sql("(#{substring}) OR (#{distance}) <= 0.5"))
              .order(Arel.sql("(#{prefix}) DESC, (#{distance}) ASC, first_name ASC"))
              .limit(limit)
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

  ######################
  # Annual check-in    #
  ######################

  CHECK_IN_SNOOZE_PERIOD = 7.days
  CHECK_IN_DISMISSAL_LIMIT = 2

  # Accounts-only interstitial: is this instructor-like user due for their
  # annual "still accurate?" check-in. Never applies to students/unknown-role
  # users, brand-new accounts, or users with no adoption signal to confirm.
  def annual_check_in_due?
    return false unless check_in_eligible_role?
    return false unless created_at.present? && created_at < 1.year.ago
    return false unless has_check_in_adoption_signal?
    return false if check_in_completed_at.present? && check_in_completed_at >= annual_check_in_school_year_start
    return false if check_in_snoozed?

    true
  end

  # Design: dismissable twice, then the check-in becomes a hard gate.
  def check_in_required?
    annual_check_in_due? && effective_check_in_dismissal_count >= CHECK_IN_DISMISSAL_LIMIT
  end

  def check_in_eligible_role?
    User.non_student_known_roles.include?(role)
  end

  def has_check_in_adoption_signal?
    user_books.exists? || adoptions.exists? || adoption_reports.exists?
  end

  # Dismissal counts (and the ability to snooze again) reset when a new
  # school year starts, so a dismissal from a prior year never counts
  # toward the current year's 2-dismissal limit.
  def effective_check_in_dismissal_count
    return 0 if check_in_dismissed_at.blank? || check_in_dismissed_at < annual_check_in_school_year_start

    check_in_dismissal_count
  end

  def check_in_snoozed?
    check_in_dismissed_at.present? && check_in_dismissed_at >= CHECK_IN_SNOOZE_PERIOD.ago
  end

  def annual_check_in_school_year_start
    Time.zone.local(SchoolYear.base_year_for(Time.zone.today), 8, 1)
  end

  # Consecutive prior school years with at least one reported adoption
  # (AdoptionReport, from either the check-in or the books-page modal),
  # counted backward starting the year immediately before the current/
  # pending one. Powers the streak banner: 0 omits it, 1 uses singular
  # copy, 2+ uses "N years reported in a row."
  def check_in_streak_years
    reported_base_years = adoption_reports.distinct.pluck(:school_year).filter_map do |label|
      SchoolYear.base_year_from_string(label)
    end.to_set

    streak = 0
    base_year = SchoolYear.base_year_for(Time.zone.today) - 1

    while reported_base_years.include?(base_year)
      streak += 1
      base_year -= 1
    end

    streak
  end

  ######################
  # LMS question       #
  ######################

  # Self-reported answer to the Overview "do you use an LMS?" card.
  # Values are stored as-is in `lms_used`; nil means unanswered.
  LMS_OPTIONS = {
    'canvas' => 'Canvas',
    'blackboard' => 'Blackboard',
    'moodle' => 'Moodle',
    'd2l' => 'D2L',
    'schoology' => 'Schoology',
    'other' => 'Other',
    'none' => 'No LMS'
  }.freeze

  validates :lms_used, inclusion: { in: LMS_OPTIONS.keys }, allow_nil: true

  def lms_answered?
    lms_used.present?
  end

  def lms_question_dismissed?
    lms_prompt_dismissed_at.present?
  end

  # Card is shown once, until the instructor answers or dismisses it.
  def lms_question_pending?
    !lms_answered? && !lms_question_dismissed?
  end

  def lms_label
    LMS_OPTIONS[lms_used]
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

  def books_used_details_valid
    return if books_used_details.blank?

    allowed_keys = %w[num_students_using_book how_using_book]
    books_used_details.each do |book, details|
      if details.keys.any? { |key| !allowed_keys.include?(key) }
        errors.add(:books_used_details, "contains unallowed keys")
      end
    end
  end

end
