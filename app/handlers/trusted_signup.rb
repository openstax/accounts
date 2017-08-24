class TrustedSignup

  attr_reader :user_state, :attrs

  lev_handler

  protected

  def authorized?
    true
  end

  def setup
    @attrs = request.session['trusted_data']
    @user_state = options[:user_state]
  end

  def handle
    user = User.new
    user.role = attrs['role']
    user.full_name = attrs['name']
    if user.student?
      user.state = 'activated'
    end
    user.save

    transfer_errors_from(user, {type: :verbatim}, true)

    ci = user.contact_infos.build(
      type: 'EmailAddress',
      value: attrs['email']
    )
    ci.verified = true
    ci.save

    transfer_errors_from(ci, {type: :verbatim}, true)

    user_state.sign_in!(user)
    outputs[:user] = user
  end

end
