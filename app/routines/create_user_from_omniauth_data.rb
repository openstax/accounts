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
                    email: data.email,  # TODO this is not used! Change CreateUser to use named arguments and remove this
                    ensure_no_errors: true)

    # TODO change routines that just take an (options={}) argument so we can
    # move toward more explicit / less error-prone routines.

    run(TransferOmniauthData, data, outputs.user)
  end

end
