
class TransferAuthentications

  lev_routine

  protected

  def exec(authentications, target_user)
    authentications = [authentications] if !(authentications.is_a? Array)
    authentications.each do |authentication|
      authentication.update_attribute(:user_id, target_user.id)
    end
  end

end