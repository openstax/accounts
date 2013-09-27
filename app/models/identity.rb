class Identity < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :user
  
  validates :password, presence: true, 
                       length: {minimum: 8, maximum: 40}

  attr_accessible :password_digest, :password, :password_confirmation, :user_id
end
