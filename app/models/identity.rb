class Identity < OmniAuth::Identity::Models::ActiveRecord
  attr_accessible :password_digest, :password, :password_confirmation
end
