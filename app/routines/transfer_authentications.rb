# Firstly, persists or updates (with `update_attributes`) an `Authentication` for the given user.
#
# Secondly, if the authentication(s) already belonged to a user, and
# that user can be destroyed, then we destroy that user.
# Otherwise, that user will have their authentication taken away.
class TransferAuthentications
  lev_routine
  uses_routine DestroyUser

  protected #################

  def exec(authentications, newer_user)
    authentications = [authentications] if !(authentications.is_a?(Array))
    authentications.each do |authentication|
      existing_user = authentication.user
      authentication.update(user_id: newer_user.id)
      transfer_errors_from(authentication, {type: :verbatim}, :fail_if_errors)

      if existing_user && can_be_destroyed?(existing_user)
        run(DestroyUser, existing_user) # to avoid orphaned User records.
      end
    end
  end

  private ###################

  # The user must have already tried to signup with the given authentication.
  def can_be_destroyed?(user)
    !user.activated? && user.reload.authentications.empty?
  end
end
