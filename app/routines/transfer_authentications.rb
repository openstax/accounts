# TLDR: Persists or updates an `Authentication` for the given user (using `update_attributes`).
#
# For each `Authentication`, if it's a new `Authentication`, then we persist it for the given user.
# But if it's an EXISTING `Authentication` belonging to another user,
# first we transfer it to the given user.
# Then, we destroy the previous user if it can be destroyed.
class TransferAuthentications
  lev_routine
  uses_routine DestroyUser

  protected ####################

  def exec(authentications, newer_user)
    authentications = [authentications] if !(authentications.is_a?(Array))
    authentications.each do |authentication|
      existing_user = authentication.user
      authentication.update_attributes(user_id: newer_user.id)
      transfer_errors_from(authentication, {type: :verbatim}, :fail_if_errors)
      # transfer_errors_from(authentication, {scope: :user_or_something}, :fail_if_errors)

      if existing_user && can_be_destroyed?(existing_user)
        run(DestroyUser, existing_user) # to avoid orphaned User records.
      end
    end
  end

  private ####################

  # The user must have already tried to signup with the given authentication.
  def can_be_destroyed?(user)
    !user.is_activated? && user.reload.authentications.empty?
  end
end
