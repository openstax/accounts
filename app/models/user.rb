class User < ActiveRecord::Base
  # devise :omniauthable, :rememberable, :trackable

  has_many :authentications

  attr_accessible :username

end
