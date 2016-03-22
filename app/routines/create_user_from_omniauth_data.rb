class CreateUserFromOmniauthData

  lev_routine

  uses_routine CreateUser,
               translations: { outputs: { type: :verbatim } }
  uses_routine TransferOmniauthData

  protected

  def exec(data)
    # This routine is not called for identity, so error out
    raise Unexpected if data.provider == 'identity'

    run(CreateUser, username: data.nickname,
                    first_name: data.first_name,
                    last_name: data.last_name,
                    full_name: data.name,
                    ensure_no_errors: true,
                    state: 'new_social')

    # TODO change routines that just take an (options={}) argument so we can
    # move toward more explicit / less error-prone routines.

    run(TransferOmniauthData, data, outputs.user)
  end

end
