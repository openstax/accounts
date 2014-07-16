class User < ActiveRecord::Base

  USERNAME_DISCARDED_CHAR_REGEX = /[^A-Za-z\d_]/
  USERNAME_MAX_LENGTH = 50

  belongs_to :person, inverse_of: :users

  has_one :identity, dependent: :destroy, inverse_of: :user

  has_many :authentications, dependent: :destroy, inverse_of: :user
  has_many :application_users, dependent: :destroy, inverse_of: :user
  has_many :contact_infos, dependent: :destroy, inverse_of: :user

  has_many :message_recipients, inverse_of: :user, :dependent => :destroy
  has_many :received_messages, through: :message_recipients, source: :message
  has_many :sent_messages, class_name: 'Message'

  has_many :group_users, dependent: :destroy, inverse_of: :user
  has_many :groups, through: :group_users
  has_many :oauth_applications, through: :groups

  has_many :owned_groups, class_name: 'Group',
           foreign_key: :owner_id, inverse_of: :owner

  before_validation :normalize_username

  validates :username, presence: true, 
                       uniqueness: { case_sensitive: false },
                       length: {minimum: 3, maximum: USERNAME_MAX_LENGTH}, 
                       format: { with: /^[A-Za-z\d_]+$/ }

  delegate_to_routine :destroy

  attr_accessible :username

  attr_readonly :uuid

  before_create :generate_uuid

  before_create :make_first_user_an_admin

  before_save :add_unread_update

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
    result = full_name.present? ? full_name : guessed_full_name || username
    title.present? ? "#{title} #{result}" : result
  end

  def guessed_full_name
    first_name.present? && last_name.present? ? "#{first_name} #{last_name}" : nil
  end

  def guessed_first_name
    full_name.present? ? full_name.split("\s")[0] : nil
  end

  def guessed_last_name
    full_name.present? ? full_name.split("\s").drop(1).join(' ') : nil
  end

  def casual_name
    first_name.present? ? first_name : username
  end

  def add_unread_update
    # Returns false if the update fails (aborting the save transaction)
    AddUnreadUpdateForUser.call(self).errors.none?
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
    self.username = username.gsub(USERNAME_DISCARDED_CHAR_REGEX, '').downcase
  end

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def make_first_user_an_admin
    self.is_administrator = true if User.count == 0
  end

end
