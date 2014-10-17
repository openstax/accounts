class UsersUpdate

  include Lev::Handler

  paramify :user do
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :current_password, type: String
    attribute :password, type: String
    attribute :password_confirmation, type: String
  end

  protected

  def authorized?
    true
  end

  def handle
    identity_attributes = user_params.as_hash(:password, :password_confirmation)
    user_attributes = user_params.as_hash(:username, :first_name, :last_name,
                                          :full_name, :title)

    unless caller.identity.nil? || (user_params.current_password.blank? && \
         user_params.password.blank? && user_params.password_confirmation.blank?)
      fatal_error(code: :wrong_password,
                  message: 'The password provided did not match our records.') \
        unless caller.identity.authenticate user_params.current_password

      caller.identity.update_attributes(identity_attributes)
      transfer_errors_from(caller.identity, {type: :verbatim}, true)
    end

    caller.update_attributes(user_attributes)
    transfer_errors_from(caller, {type: :verbatim}, true)
  end
end
