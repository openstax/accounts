class User < ActiveRecord::Base

  belongs_to :person
  has_many :authentications, :dependent => :destroy
  has_many :contact_infos, :dependent => :destroy

  delegate_to_algorithm :destroy

  attr_accessible :username

  def is_administrator?
    is_administrator
  end

  def is_anonymous?
    false
  end

end
