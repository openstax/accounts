require 'singleton'

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

  # Necessary if an anonymous user ever runs into an Exception
  # or else the developer email doesn't work
  def username
    'anonymous'
  end

  def full_name
    "Anonymous User"
  end

  def casual_name
    full_name
  end

end