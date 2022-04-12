module LookupUsers
  # Case-sensitive searches because legacy reasons...
  # we planned to migrate CNX users which had case-sensitive accounts.

  def self.by_verified_email_or_username(email_or_username)
    email_or_username = email_or_username.try(:strip)

    return [] if email_or_username.blank?

    # Case sensitive username search
    User.where(username: email_or_username).tap do |matches|
      raise IllegalState if matches.many? # User validations should prevent this
      return [matches.first] if matches.one?
    end

    # Case-insensitive username search
    User.where('lower(username) = ?', email_or_username.downcase).tap do |matches|
      # multiple case insensitive matches not allowed/supported; should probably have
      # some nice UI for this case, but in production this is only 6 old users, so we
      # punt.
      return [] if matches.many?

      return [matches.first] if matches.one?
    end

    return self.by_verified_email(email_or_username)
  end

  def self.by_verified_email(email)
    # Case-sensitive email search
    ContactInfo.verified
               .where(value: email)
               .preload(:user)
               .tap do |matches|
      return matches.map(&:user) if matches.any?
    end
    # Case-insensitive email search
    ContactInfo.verified
               .where('lower(value) = ?', email.downcase)
               .preload(:user)
               .tap do |matches|
      return matches.map(&:user) if matches.any?
    end
    return []
  end

  def self.by_email(email)
    # Case-insensitive email search
    ContactInfo.where('lower(value) = ?', email.downcase)
               .preload(:user)
               .tap do |matches|
      return matches.map(&:user) if matches.any?
    end
    return []
  end

  def self.by_email_or_username(email_or_username)
    # Case-insensitive username search
    User.where('lower(username) = ?', email_or_username.downcase).tap do |matches|
      # multiple case insensitive matches not allowed/supported; should probably have
      # some nice UI for this case, but in production this is only 6 old users, so we
      # punt.
      return [] if matches.many?

      return [matches.first] if matches.one?
    end

    # Case-insensitive email search
    ContactInfo.where('lower(value) = ?', email_or_username.downcase)
               .preload(:user)
               .tap do |matches|
      return matches.map(&:user) if matches.any?
    end
    return []
  end

end
