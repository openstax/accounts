require 'singleton'

class AnonymousUserIsImmutableError < StandardError; end

class AnonymousUser
  include Singleton

  def is_administrator?
    false
  end

  def student?
    false
  end

  def oauth_applications
    []
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

  def activated?
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

  def temporary?
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
      status == 'no_faculty_info'
    end

    define_method "#{status}!" do
      raise AnonymousUserIsImmutableError, "Cannot set faculty status on the AnonymousUser."
    end
  end

  def faculty_status
    'no_faculty_info'
  end

  def faculty_status=(status)
    raise AnonymousUserIsImmutableError, "Cannot set faculty status on the AnonymousUser."
  end

  User.school_types.each do |type, value|
    define_method "#{type}?" do
      type == 'unknown_school_type'
    end

    define_method "#{type}!" do
      raise AnonymousUserIsImmutableError, "Cannot set school type on the AnonymousUser."
    end
  end

  def school_type
    'unknown_school_type'
  end

  def school_type=(type)
    raise AnonymousUserIsImmutableError, "Cannot set school type on the AnonymousUser."
  end

  User.school_locations.each do |location, value|
    define_method "#{location}?" do
      location == 'unknown_school_location'
    end

    define_method "#{location}!" do
      raise AnonymousUserIsImmutableError, "Cannot set school location on the AnonymousUser."
    end
  end

  def school_location
    'unknown_school_location'
  end

  def school_location=(type)
    raise AnonymousUserIsImmutableError, "Cannot set school location on the AnonymousUser."
  end
end
