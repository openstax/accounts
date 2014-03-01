# # An API-only sibling to AnonymousUser.  In API land, the caller of an API
# # can be an application unassociated to a human user.  This UnspecifiedUser
# # is our alternative to having a nil User in this case.

# class NoUser
#   include Singleton

#   def is_administrator?
#     false
#   end

#   def is_specified?
#     false
#   end

#   def id
#     nil
#   end

#   # Necessary if an anonymous user ever runs into an Exception
#   # or else the developer email doesn't work
#   def username
#     'no_user'
#   end

#   def full_name
#     "No User"
#   end

#   def casual_name
#     full_name
#   end
# end