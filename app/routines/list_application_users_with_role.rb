class ListApplicationUsersWithRole
  lev_routine transaction: :no_transaction

  protected

  def exec(application, role)
    user_ids = ApplicationUser
      .where(application_id: application.id)
      .where("roles <> '{}'")
      .where('roles @> ARRAY[?]::varchar[]', role)
      .pluck(:user_id)

    outputs.users = User.where(id: user_ids).order(:last_name, :first_name)
  end
end
