

class Handlers::UpdateUser

  include Handlers::Base

protected

  def setup
    @form_user = User.find(params['user_id'])
  end

  def authorized?
    caller.is_administrator? || caller == @form_user
  end

  def exec
    @form_user.update_attributes(username: params['username'])
    
    # do stuff
  end

end
