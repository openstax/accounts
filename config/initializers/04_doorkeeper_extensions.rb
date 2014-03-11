# Add some fields to Doorkeeper Application
Doorkeeper::Application.class_eval do
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
