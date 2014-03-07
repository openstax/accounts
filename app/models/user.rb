class User < ActiveRecord::Base

  USERNAME_DISCARDED_CHAR_REGEX = /[^A-Za-z\d_]/
  USERNAME_MAX_LENGTH = 50

  belongs_to :person
  has_many :authentications, :dependent => :destroy
  has_many :contact_infos, :dependent => :destroy
  has_one :identity, :dependent => :destroy

  before_validation :normalize_username

  validates :username, presence: true, 
                       uniqueness: { case_sensitive: false },
                       length: {minimum: 3, maximum: USERNAME_MAX_LENGTH}, 
                       format: { with: /^[A-Za-z\d_]+$/ }

  delegate_to_routine :destroy

  attr_accessible :username

  def is_administrator?
    is_administrator
  end

  def is_anonymous?
    false
  end

  def is_human?
    true
  end

  def is_application?
    false
  end

  def name
    full_name || derived_full_name || username
  end

  def guessed_full_name
    first_name && last_name ? "#{first_name} #{last_name}" : nil
  end

  def guessed_first_name
    full_name ? full_name.split("\s")[0] : nil
  end

  def guessed_last_name
    full_name ? full_name.split("\s").drop(1).join(' ') : nil
  end

  def casual_name
    first_name || username
  end

  def can_be_read_by?(user)
    raise NotYetImplemented
  end

  def can_be_updated_by?(user)
    raise NotYetImplemented
  end

  def can_be_destroyed_by?(user)
    raise NotYetImplemented
  end

  ##########################
  # Access Control Helpers #
  ##########################

  def can_read?(resource)
    resource.can_be_read_by?(self)
  end
  
  def can_create?(resource)
    resource.can_be_created_by?(self)
  end
  
  def can_update?(resource)
    resource.can_be_updated_by?(self)
  end
    
  def can_destroy?(resource)
    resource.can_be_destroyed_by?(self)
  end

  def can_sort?(resource)
    resource.can_be_sorted_by?(self)
  end

protected

  def normalize_username
    self.username = username.gsub(USERNAME_DISCARDED_CHAR_REGEX,'').downcase
  end

end
