

# needs to be named something else and taken out of the Handlers namespace

class UpdateUser

  include Lev::Handler

protected

  def setup
    @form_user = User.find(params['user_id'])
  end

  def authorized?
    caller.is_administrator? || caller == @form_user
  end

  def handle
    @form_user.update_attributes(username: params['username'])
    
    # do stuff
  end

end
