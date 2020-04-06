# Users who started signing up in the old flow but never filled out their profile information
# are in the state 'needs_profile'. In the new flow, that translates to 'unverified'.
# So we update their state to match the new flow.
module Newflow
  class EnsureUnverifiedUser
    lev_routine

    def exec(user)
      if user.state == 'needs_profile'
        user.update_attributes(state: 'unverified', is_newflow: true)
        transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)

        SecurityLog.create(
          event_type: :user_updated,
          user: user,
          event_data: {
            state_was: 'needs_profile',
            state_changed_to: 'unverified'
          }
        )
      end
      outputs.user = user
    end
  end
end
