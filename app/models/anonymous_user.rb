require 'singleton'

class AnonymousUserIsImmutableError < StandardError; end

class AnonymousUser
  include Singleton

  def is_administrator?
    false
  end

  def is_anonymous?
    true
  end

  def is_human?
    true
  end

  def is_application?
    false
  end

  def is_activated?
    false
  end

  def is_needs_profile?
    false
  end

  def id
    nil
  end

  def authentications
    []
  end

  def identity
    nil
  end

  def is_temp?
    false
  end

  def is_new_social?
    false
  end

  def applications
    []
  end

  # Necessary if an anonymous user ever runs into an Exception
  # or else the developer email doesn't work
  def username
    'anonymous'
  end

  def full_name
    "Anonymous User"
  end

  def first_name
    "Anonymous"
  end

  def last_name
    "User"
  end

  def title; end
  def suffix; end

  def contact_infos
    []
  end

  def email_addresses
    []
  end

  def casual_name
    full_name
  end

  User.faculty_statuses.each do |status, value|
    define_method "#{status}?" do
      User::DEFAULT_FACULTY_STATUS.to_s == status
    end

    define_method "#{status}!" do
      raise AnonymousUserIsImmutableError, "Cannot set faculty status on the AnonymousUser."
    end
  end

  def faculty_status
    User::DEFAULT_FACULTY_STATUS.to_s
  end

  def faculty_status=(status)
    raise AnonymousUserIsImmutableError, "Cannot set faculty status on the AnonymousUser."
  end

end
