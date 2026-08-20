class ListApplicationUsersWithRole
  lev_routine transaction: :no_transaction

  protected

  def exec(application, role)
    outputs.users = User
      .joins(:application_users)
      .where(application_users: { application_id: application.id })
      .where("application_users.roles <> '{}'")
      .where('application_users.roles @> ARRAY[?]::varchar[]', role)
      .order(:last_name, :first_name)
  end
end
