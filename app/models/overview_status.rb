# Where an instructor's or staff member's account stands, for the overview's greeting,
# badges, subtitle and status callout. The views ask for those and hold no state
# conditionals of their own.
#
# Copy lives under `overview_status` in config/locales/en.yml. The pending-review
# wording matches the "We're processing your request" screen a user saw after
# signup, and the verify-another-way wording matches the SheerID step's alternatives.
class OverviewStatus
  NEW_ACCOUNT_WINDOW = 14.days
  REJECTED_HELP_URL = 'https://help.openstax.org/s/article/My-request-to-access-Instructor-Resources-was-rejected'.freeze
  # States where the one-time profile nudge may stand in for the state's own callout.
  NUDGE_STATES = %i[verified checking unstarted].freeze

  Badge = Struct.new(:label, :tone, keyword_init: true)
  Link = Struct.new(:label, :path, keyword_init: true)
  Callout = Struct.new(:id, :eyebrow, :title, :paragraphs, :primary, :secondary, :nudge, keyword_init: true) do
    def nudge?
      nudge == true
    end
  end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def self.greeting_for(user)
    new(user).greeting
  end

  # One of: :staff, :staff_unfinished, :verified, :rejected, :pending_review,
  # :checking (SheerID still deciding), :needs_another_way (SheerID rejected,
  # expired or errored), :unstarted (no outcome yet and no review requested).
  def state
    @state ||= compute_state
  end

  # New means made in the last 14 days and not yet seen on a later UTC day than
  # the one the account was created. last_signed_in_at and last_seen_at are
  # columns on the user, so this costs no query.
  def new_account?
    created = user.created_at
    return false if created.nil? || created < NEW_ACCOUNT_WINDOW.ago

    [user.last_signed_in_at, user.last_seen_at].compact.none? { |at| at.utc.to_date > created.utc.to_date }
  end

  def greeting
    key = new_account? ? 'new' : 'returning'
    name = user.first_name.to_s.strip
    if name.present?
      I18n.t("overview_status.greeting.#{key}_with_name", name: name)
    else
      I18n.t("overview_status.greeting.#{key}")
    end
  end

  def badges
    list = [status_badge]
    list << Badge.new(label: user.school.name, tone: :school) if user.school&.name.present?
    list
  end

  def subtitle
    I18n.t("overview_status.subtitle.#{subtitle_key}", school: ERB::Util.html_escape(school_name)).html_safe
  end

  def add_school_link?
    school_name.blank?
  end

  def callout(show_profile_nudge: false)
    return nudge_callout if show_profile_nudge && NUDGE_STATES.include?(state)

    case state
    when :verified then enrichment_callout
    when :rejected then rejected_callout
    when :pending_review then pending_review_callout
    when :checking then user.is_profile_complete? ? checking_callout : finish_profile_callout
    when :needs_another_way then needs_another_way_callout
    when :unstarted then user.step_3_complete? ? finish_profile_callout : start_verification_callout
    when :staff_unfinished then finish_profile_callout
    end
  end

  def verified_instructor?
    user.confirmed_faculty?
  end

  def staff?
    user.completed_non_teaching_profile?
  end

  def school_name
    user.school&.name.presence || user.self_reported_school.presence
  end

  private

  def routes
    Rails.application.routes.url_helpers
  end

  def t(key, **opts)
    I18n.t("overview_status.#{key}", **opts)
  end

  def compute_state
    return :staff if staff?
    return :verified if user.confirmed_faculty?
    return :rejected if user.rejected_faculty?
    return :pending_review if user.pending_faculty? || user.is_educator_pending_cs_verification?
    return :checking if user.pending_sheerid?
    return :needs_another_way if user.rejected_by_sheerid? || user.sheerid_expired? || user.sheerid_error?
    # Finished step 4 with no SheerID outcome: CompleteProfile sends these to the CX queue.
    return :pending_review if user.is_profile_complete?
    return :staff_unfinished if staff_role_in_progress?

    :unstarted
  end

  def staff_role_in_progress?
    user.role.present? && !user.unknown_role? && User::TEACHING_ROLES.exclude?(user.role.to_s)
  end

  def status_badge
    case state
    when :staff then Badge.new(label: user.staff_role_label, tone: :info)
    when :verified then Badge.new(label: t('badge.verified'), tone: :verified)
    when :rejected then Badge.new(label: t('badge.not_active'), tone: :info)
    when :pending_review, :checking then Badge.new(label: t('badge.pending'), tone: :pending)
    else Badge.new(label: t('badge.finish'), tone: :pending)
    end
  end

  def subtitle_key
    case state
    when :staff then school_name.present? ? 'staff_school' : 'staff'
    when :verified then school_name.present? ? 'verified_school' : 'verified'
    when :pending_review then 'pending'
    when :staff_unfinished, :unstarted then 'incomplete'
    else state.to_s
    end
  end

  def nudge_callout
    body = I18n.t(state == :verified ? :"profile_nudge_banner.body" : :"profile_nudge_banner.body_unverified")
    Callout.new(id: 'profile-nudge-callout', nudge: true, paragraphs: [body])
  end

  def support_link
    Link.new(label: t('callout.contact_support'), path: routes.account_support_path)
  end

  def enrichment_callout
    return unless user.profile_needs_enrichment?

    Callout.new(
      id: 'enrich-profile-callout', eyebrow: t('callout.enrich.eyebrow'), title: t('callout.enrich.title'),
      paragraphs: [t('callout.enrich.body')],
      primary: Link.new(label: t('callout.enrich.button'), path: routes.educator_profile_form_path)
    )
  end

  def rejected_callout
    Callout.new(
      id: 'rejected-callout', eyebrow: t('callout.rejected.eyebrow'), title: t('callout.rejected.title'),
      paragraphs: [t('callout.rejected.body')],
      primary: Link.new(label: t('callout.rejected.button'), path: REJECTED_HELP_URL)
    )
  end

  def pending_review_callout
    email = user.email_addresses.last&.value
    intro = if email
              t('callout.pending_review.body_with_email', email: ERB::Util.html_escape(email)).html_safe
            else
              t('callout.pending_review.body')
            end
    Callout.new(
      id: 'verification-callout', eyebrow: t('callout.pending_review.eyebrow'),
      title: t('callout.pending_review.title'),
      paragraphs: [intro, t('callout.in_the_meantime')],
      secondary: support_link
    )
  end

  def checking_callout
    Callout.new(
      id: 'verification-callout', eyebrow: t('callout.checking.eyebrow'), title: t('callout.checking.title'),
      paragraphs: [t('callout.checking.body'), t('callout.in_the_meantime')],
      secondary: support_link
    )
  end

  # A finished profile closes the CS form, so those users can only reach support.
  def needs_another_way_callout
    return another_way_callout unless user.is_profile_complete?

    Callout.new(
      id: 'verification-callout', eyebrow: t('callout.needs_support.eyebrow'),
      title: t('callout.needs_support.title'),
      paragraphs: [t(user.rejected_by_sheerid? ? 'callout.needs_support.body_rejected' : 'callout.needs_support.body_unfinished')],
      primary: support_link
    )
  end

  def another_way_callout
    Callout.new(
      id: 'verify-another-way-callout', eyebrow: t('callout.another_way.eyebrow'), title: t('callout.another_way.title'),
      paragraphs: [I18n.t(:"login_signup_form.alternative_manual_verification_description")],
      primary: Link.new(label: I18n.t(:"login_signup_form.alternative_manual_verification"),
                        path: routes.educator_cs_verification_form_path)
    )
  end

  def start_verification_callout
    Callout.new(
      id: 'complete-signup-callout', eyebrow: t('callout.finish_eyebrow'), title: t('callout.start_verification.title'),
      paragraphs: [I18n.t(:"login_signup_form.sheerid_verification_page_description")],
      primary: Link.new(label: t('callout.continue'), path: routes.educator_sheerid_form_path)
    )
  end

  def finish_profile_callout
    staff = state == :staff_unfinished
    Callout.new(
      id: 'complete-signup-callout', eyebrow: t('callout.finish_eyebrow'),
      title: t(staff ? 'callout.finish_profile.title_staff' : 'callout.finish_profile.title'),
      paragraphs: [t(staff ? 'callout.finish_profile.body_staff' : 'callout.finish_profile.body')],
      primary: Link.new(label: t('callout.continue'),
                        path: staff ? routes.staff_details_form_path : routes.educator_profile_form_path)
    )
  end
end
