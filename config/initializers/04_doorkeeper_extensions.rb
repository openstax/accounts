# Add some fields to Doorkeeper Application
Doorkeeper::Application.class_eval do
  attr_accessible :trusted

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
