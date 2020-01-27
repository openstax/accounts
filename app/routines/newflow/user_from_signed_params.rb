module Newflow
  class UserFromSignedParams
    lev_routine

    protected ###############

    def exec(sp)
      role = User.roles[sp['role']] ? sp['role'] : nil

      user = User.new(state: 'unverified', role: role, self_reported_school: sp['school'])
      user.external_uuids.find_or_initialize_by(uuid: sp['uuid'])
      user.signed_external_data = sp.merge(role: role) # I think `sp.merge(role: role)` may correct/update the role but otherwise is the same as just doing `sp`

      user.full_name = sp['name']

      user.save
      transfer_errors_from(user, {type: :verbatim}, true)
      outputs.user = user
    end
  end
end
