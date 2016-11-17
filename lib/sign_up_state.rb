module SignUpState

  def saved_role
    session[:signup].try(:[], 'role')
  end

  def saved_signup_contact_info
    @saved_signup_contact_info ||= SignupContactInfo.find_by(id: session[:signup].try(:[],'ci_id'))
  end

  def saved_email
    @saved_email ||= saved_signup_contact_info.try(:value)
  end

  def save_signup_state(role:, signup_contact_info_id:)
    session[:signup] = {
      role: role,
      ci_id: signup_contact_info_id
    }
  end

  def clear_signup_state
    session.delete(:signup)
  end

end
