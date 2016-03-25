class TransferAuthentications

  lev_routine

  uses_routine DestroyUser

  protected

  def exec(authentications, target_user)
    authentications = [authentications] if !(authentications.is_a? Array)
    authentications.each do |authentication|
      authentication_user = authentication.user
      authentication.update_attribute(:user_id, target_user.id)
      run(DestroyUser, authentication_user) \
        if authentication_user && !authentication_user.is_activated? && \
           authentication_user.reload.authentications.empty?
    end
  end

end
