class ListApplicationUserRoles
  lev_routine transaction: :no_transaction

  protected

  def exec(application)
    outputs.roles = ApplicationUser
      .where(application_id: application.id)
      .where("roles <> '{}'")
      .distinct
      .pluck(Arel.sql('unnest(roles)'))
      .reject(&:blank?)
      .sort
  end
end
