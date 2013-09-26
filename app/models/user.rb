class User < ActiveRecord::Base

  belongs_to :person
  has_many :authentications, :dependent => :destroy
  has_many :contact_infos, :dependent => :destroy

  validates :username, presence: true, uniqueness: true

  delegate_to_routine :destroy

  attr_accessible :username

  def is_administrator?
    is_administrator
  end

  def is_anonymous?
    false
  end

end
