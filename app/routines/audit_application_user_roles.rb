class AuditApplicationUserRoles
  lev_routine transaction: :no_transaction

  protected

  def exec(application)
    outputs.roles = ApplicationUser
      .where(application_id: application.id)
      .distinct
      .pluck(Arel.sql('unnest(roles)'))
      .sort
  end
end
