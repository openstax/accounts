class IdentitiesUpdate

  include Lev::Handler

  paramify :identity do
    attribute :current_password, type: String
    attribute :password, type: String
    attribute :password_confirmation, type: String
  end

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:update, caller, caller.identity)
  end

  def handle
    fatal_error(code: :wrong_password,
                message: 'The password provided did not match our records',
                offending_inputs: :current_password) \
      unless caller.identity.authenticate identity_params.current_password

    identity_attributes = identity_params.as_hash(:password,
                                                  :password_confirmation)
    caller.identity.update_attributes(identity_attributes)
    transfer_errors_from(caller.identity, {type: :verbatim}, true)
  end
end
