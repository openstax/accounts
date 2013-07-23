class User < ActiveRecord::Base
  # devise :omniauthable, :rememberable, :trackable

  has_many :authentications

  attr_accessible :username

  def self.create_with_omniauth(auth)
    # you should handle here different providers data
    # eg. case auth['provider'] ..
    # create(name: auth['info']['name'])
    create(username: SecureRandom.hex(30))
    # IMPORTANT: when you're creating a user from a strategy that
    # is not identity, you need to set a password, otherwise it will fail
    # I use: user.password = rand(36**10).to_s(36)
  end
end
