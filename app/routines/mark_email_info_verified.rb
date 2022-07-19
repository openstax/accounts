class MarkEmailVerified

  lev_routine

  protected

  def exec(email)
    case email
    when EmailAddress
      email.verified = true
    else
      raise ArgumentError, "Invalid email class: #{email.class.name}", caller
    end
    email.save

    transfer_errors_from(email, {type: :verbatim}, true)
  end

end
