module LookupUsers

  def self.by_email_or_username(email_or_username)
    email_or_username = email_or_username.try(:strip)

    return [] if email_or_username.blank?

    contact_infos = ContactInfo.verified.where(value: email_or_username).preload(:user)
    [User.where(username: email_or_username).first || contact_infos.map(&:user)].flatten
  end

end
