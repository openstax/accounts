class SignupFromLms

  attr_reader :user_state, :lms

  lev_handler

  protected

  def authorized?
    true
  end

  def setup
    @lms = request.session['lms']
    @user_state = options[:user_state]
  end

  def handle
    user = User.new
    user.role = lms['role']
    user.full_name = lms['name']
    if user.student?
      user.state = 'activated'
    end
    user.save

    transfer_errors_from(user, {type: :verbatim}, true)

    ci = user.contact_infos.build(
      type: 'EmailAddress',
      value: lms['email'],

    )
    ci.verified = true
    ci.save

    transfer_errors_from(ci, {type: :verbatim}, true)

    user_state.sign_in!(user)
    outputs[:user] = user
  end

end
