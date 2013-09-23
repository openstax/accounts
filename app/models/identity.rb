class Identity < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :user
  attr_accessible :password_digest, :password, :password_confirmation, :user_id
end
