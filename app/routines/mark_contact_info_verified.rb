class MarkContactInfoVerified

  include Lev::Routine

protected

  def exec(contact_info)
    contact_info.update_attributes(
      confirmation_code: nil,
      verified: true,
    )

    transfer_errors_from(contact_info, {scope: :verbatim})
  end

end