# A "user" (lowercase 'u') of an API can take one of several forms.
# 
#   1. It can just be a User (capital 'U') based on session data (e.g. 
#      someone who logs into this site and then uses this site's Backbone 
#      interface).
#   2. It can be a combination of a Doorkeeper Application and a User, 
#      given via OAuth's Authorization or Implicit flows.
#   3. It can just be a Doorkeeper Application, given through OAuth's
#      Client Credentials flow.  
# 
# This API class gives us a way to abstract out these cases and also
# gives us accessors to get the Application and User objects, if available.

class ApiUser

  def initialize(doorkeeper_token, non_doorkeeper_user_proc)
    # If we have a doorkeeper_token, derive the Application and User
    # from it.  If not, we're in case #1 above and the User should be 
    # retrieved from the alternative proc provided in arguments and 
    # there is no application.
    #
    # In both cases, don't actually retrieve any data -- just save off
    # procs that can get it for us.  This could save us some queries.

    if doorkeeper_token
      @application_proc = lambda { doorkeeper_token.application }
      @user_proc = lambda {
        doorkeeper_token.resource_owner_id ? 
          User.find(doorkeeper_token.resource_owner_id) : 
          nil
      }
    else
      @user_proc = non_doorkeeper_user_proc
      @application_proc = lambda { nil }
    end
  end

  # Returns a Doorkeeper::Application or nil 
  # TODO should we have a NoApplication like NoUser (or maybe should
  # NoUser just be replaced with nil)
  def application
    @application ||= @application_proc.call
  end

  # Can return an instance of User, AnonymousUser, or nil
  def human_user
    @user ||= @user_proc.call
  end

  ##########################
  # Access Control Helpers #
  ##########################

  def can_do?(action, resource)
    AccessPolicy.action_allowed?(action, self, resource)
  end

  def can_read?(resource)
    can_do?(:read, resource)
  end
  
  def can_create?(resource)
    can_do?(:create, resource)
  end
  
  def can_update?(resource)
    can_do?(:update, resource)
  end
    
  def can_destroy?(resource)
    can_do?(:destroy, resource)
  end

  def can_sort?(resource)
    can_do?(:sort, resource)
  end

end
