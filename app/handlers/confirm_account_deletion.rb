class ConfirmAccountDeletion

  lev_handler

  uses_routine SoftDeleteUser

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :token_blank) if params[:token].blank?

    # Locked so two concurrent POSTs of the same link can't both pass the
    # checks below; the second waits, then fails on the cleared token.
    user = User.lock.find_by(account_deletion_token: params[:token])

    fatal_error(code: :unknown_account_deletion_token) if user.nil?
    fatal_error(code: :expired_account_deletion_token) if user.account_deletion_token_expired?
    fatal_error(code: :already_deleted) if user.is_deleted?

    run(SoftDeleteUser, user)

    outputs.user = user
  end
end
