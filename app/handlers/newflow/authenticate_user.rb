module Newflow
  # Handles log in form submission.
  # Tries to find a user by email (or username for legacy reasons),
  # then checks the password for the user.
  # If successful, outputs the user. Otherwise, fails and logs the error.
  class AuthenticateUser
    lev_handler
    include RateLimiting
    include ActionView::Helpers::UrlHelper

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
      outputs.email = login_form_params.email

      # We should be searching by email
      # but we'd like to continue to support users who only have a username.
      users = LookupUsers.by_email_or_username(login_form_params.email)

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
              :"legacy.sessions.start.multiple_users_missing_usernames.content_html",
              help_link: (
                mail_to(
                  "info@openstax.org",
                  I18n.t(:"legacy.sessions.start.multiple_users_missing_usernames.help_link_text")
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
      # Link the user to the external uuid at this point (after successfully logging in)
      transfer_signed_data_if_present(user)
    end

    private #################

    # transfer signed params data from 'unverified' user that was created
    # and then delete that user
    def transfer_signed_data_if_present(user)
      return unless (sp_user = options[:user_from_signed_params])

      sp = sp_user['signed_external_data'] # I want/need the signed params, essentially. How do I get store and get 'em?
      user.self_reported_school = sp['school']

      # link uuid from signed params
      uuid_record = UserExternalUuid.find_by(uuid: sp['uuid'])
      user.external_uuids << uuid_record
      # link email from signed params
      run(AddEmailToUser, sp['email'], user, already_verified: false)
      user.save
      transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)

      # delete the user_from_signed_params (aka.  unverified user) which was created initially
    end

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
end
