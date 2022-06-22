# Handles log in form submission.
# Tries to find a user by email (or username for legacy reasons),
# then checks the password for the user.
# If successful, outputs the user. Otherwise, fails and logs the error.
class LogInUser

  include RateLimiting
  include ActionView::Helpers::UrlHelper

  lev_handler

  paramify :login_form do
    attribute :email, type: String
    attribute :password, type: String

    validates :email, presence: true
    validates :password, presence: true
  end

  protected ###############

  def authorized?
    true
  end

  def handle
    outputs.email = login_form_params.email.squish!

    # We should be searching by email
    # but we'd like to continue to support users who only have a username.
    users = LookupUsers.by_email_or_username(login_form_params.email.squish!)

    outputs.user = user = users.first

    failure(:too_many_login_attempts, :email) if user && too_many_login_attempts?(user)

    if users.empty?
      failure(:cannot_find_user, :email)
    elsif users.many?
      if users.map(&:username).any?(&:nil?)
        fatal_error(
          code: :multiple_users_missing_usernames,
          offending_inputs: :email,
          message: I18n.t(
            :"sessions.start.multiple_users_missing_usernames.content_html",
            help_link: (
              mail_to(
                "info@openstax.org",
                I18n.t(:"sessions.start.multiple_users_missing_usernames.help_link_text")
              )
            )
          )
        )
      else
        failure(:multiple_users, :email)
      end
    end

    identity = Identity.authenticate({ user_id: user&.id }, login_form_params.password)
    failure(:incorrect_password, :password) unless identity.present?
  end

  private #################

  def failure(reason, input_field)
    fatal_error(
      code: reason,
      offending_inputs: input_field,
      message: I18n.t(:"login_signup_form.#{reason}")
    )
  end

  def too_many_login_attempts?(user)
    too_many_log_in_attempts_by_ip?(ip: request.ip) ||
    too_many_log_in_attempts_by_user?(user: user)
  end
end
