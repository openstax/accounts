class User < ActiveRecord::Base
  # devise :omniauthable, :rememberable, :trackable

  has_many :authentications

  attr_accessible :username

  def is_administrator?
    is_administrator
  end

end
