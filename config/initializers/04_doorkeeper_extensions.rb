# Add some fields to Doorkeeper Application
Doorkeeper::Application.class_eval do
  has_many :application_users, :foreign_key => :application_id,
                               :dependent => :destroy,
                               :inverse_of => :application
  has_many :users, :through => :application_users
end
