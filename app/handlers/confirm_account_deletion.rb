class ConfirmAccountDeletion

  lev_handler

  uses_routine SoftDeleteUser

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :token_blank) if params[:token].blank?

    user = User.find_by(account_deletion_token: params[:token])

    fatal_error(code: :unknown_account_deletion_token) if user.nil?
    fatal_error(code: :expired_account_deletion_token) if user.account_deletion_token_expired?

    run(SoftDeleteUser, user)

    outputs.user = user
  end
end
