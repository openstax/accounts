class SignupChangeRole
  lev_handler
  paramify :profile do
    attribute :role, type: String
  end

  def authorized?
    caller.is_needs_profile?
  end

  def handle
    caller.role = profile_params.role
    caller.save
    transfer_errors_from(caller, {type: :verbatim}, true)

  end

end
