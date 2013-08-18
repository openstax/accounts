class User < ActiveRecord::Base

  belongs_to :person
  has_many :authentications
  has_many :contact_infos

  attr_accessible :username

  def is_administrator?
    is_administrator
  end

  def is_anonymous?
    false
  end

end
