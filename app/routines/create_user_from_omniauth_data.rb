class CreateUserFromOmniauthData

  lev_routine

  uses_routine CreateUser,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(data)
    # This routine is not called for identity, so error out
    raise Unexpected if data.provider == 'identity'

    run(CreateUser, username: data.nickname,
                    first_name: data.first_name,
                    last_name: data.last_name,
                    full_name: data.name,
                    email: data.email,
                    ensure_no_errors: true)
  end

end
