class MockUserState

  def sign_in!(user)
    self.the_current_user = user
  end

  def sign_out!
    self.the_current_user = nil
  end

  def signed_in?
    self.the_current_user.present?
  end

  def current_user
    self.the_current_user
  end

  protected

  attr_accessor :the_current_user

end
