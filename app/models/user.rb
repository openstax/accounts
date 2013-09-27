class User < ActiveRecord::Base

  USERNAME_DISCARDED_CHAR_REGEX = /\.\'\-/
  USERNAME_MAX_LENGTH = 50

  belongs_to :person
  has_many :authentications, :dependent => :destroy
  has_many :contact_infos, :dependent => :destroy

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

protected

  def normalize_username
    self.username = username.gsub(USERNAME_DISCARDED_CHAR_REGEX,'').downcase
  end

end
