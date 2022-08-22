# Firstly, persists or updates (with `update_attributes`) an `Authentication` for the given user.
#
# Secondly, if the authentication(s) already belonged to a user, and
# that user can be destroyed, then we destroy that user.
# Otherwise, that user will have their authentication taken away.
class TransferAuthentications
  lev_routine

  protected

  def exec(authentications, newer_user)
    authentications = [authentications] unless authentications.is_a?(Array)
    authentications.each do |authentication|
      existing_user = authentication.user
      authentication.update_attributes(user_id: newer_user.id)
      transfer_errors_from(authentication, {type: :verbatim}, :fail_if_errors)
    end
  end
end
