class User < ActiveRecord::Base

  USERNAME_DISCARDED_CHAR_REGEX = /[^A-Za-z\d_]/
  USERNAME_MAX_LENGTH = 50

  belongs_to :person, inverse_of: :users

  has_one :identity, dependent: :destroy, inverse_of: :user

  has_many :authentications, dependent: :destroy, inverse_of: :user
  has_many :application_users, dependent: :destroy, inverse_of: :user
  has_many :contact_infos, dependent: :destroy, inverse_of: :user
  has_many :email_addresses, inverse_of: :user

  has_many :message_recipients, inverse_of: :user, :dependent => :destroy
  has_many :received_messages, through: :message_recipients, source: :message
  has_many :sent_messages, class_name: 'Message'

  has_many :group_owners, dependent: :destroy, inverse_of: :user
  has_many :owned_groups, through: :group_owners, source: :group

  has_many :group_members, dependent: :destroy, inverse_of: :user
  has_many :member_groups, through: :group_members, source: :group

  has_many :oauth_applications, through: :member_groups

  before_validation :sanitize_username

  validates :username, presence: true, 
                       uniqueness: { case_sensitive: false },
                       length: {minimum: 3, maximum: USERNAME_MAX_LENGTH}, 
                       format: { with: /^[A-Za-z\d_]+$/ }
  validates :username, uniqueness: true, on: :create

  delegate_to_routine :destroy

  attr_accessible :title, :first_name, :last_name, :full_name

  attr_readonly :uuid

  before_create :generate_uuid

  before_create :make_first_user_an_admin

  before_save :add_unread_update

  # Can remove this method definition when we upgrade to Rails 4
  def self.none
    where('0=1')
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

  def sanitize_username
    self.username = username.gsub(USERNAME_DISCARDED_CHAR_REGEX, '')
  end

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def make_first_user_an_admin
    return if Rails.env.production?
    self.is_administrator = true if User.count == 0
  end

end
