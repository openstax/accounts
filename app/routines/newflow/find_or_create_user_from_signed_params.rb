module Newflow
  class FindOrCreateUserFromSignedParams
    lev_routine

    protected ###############

    def exec(sp)
      if (existing_user = LookupUsers.by_verified_email(sp['email']).first)
        # transfer signed params to user
        existing_user.signed_external_data = sp
        existing_user.self_reported_school = sp['school']
        existing_user.role = sp['role']
        existing_user.external_uuids.find_or_initialize_by(uuid: sp['uuid'])
        existing_user.save

        outputs.user = existing_user
        return
      end

      role = User.roles[sp['role']] ? sp['role'] : nil

      user = User.new(state: 'unverified', role: role, self_reported_school: sp['school'])
      user.external_uuids.find_or_initialize_by(uuid: sp['uuid'])
      user.signed_external_data = sp.merge(role: role)
      user.full_name = sp['name']

      user.save
      outputs.user = user
      transfer_errors_from(user, {type: :verbatim}, true)
    end
  end
end
