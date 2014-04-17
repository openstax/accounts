# Add some fields to Doorkeeper Application
Doorkeeper::Application.class_eval do
  has_many :application_users, :foreign_key => :application_id,
                               :dependent => :destroy
  has_many :users, :through => :application_users

  def is_human?
    false
  end

  def is_application?
    true
  end

  def is_administrator?
    false
  end
end
