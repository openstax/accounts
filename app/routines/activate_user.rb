# Sets the passed-in user's `state` to `'activated'`
# If the user is already `activated`, then it does nothing.
class ActivateUser

  lev_routine active_job_enqueue_options: { queue: :signup_queue }

  protected ###############

  def exec(user:, role:)
    return if user.activated?

    user.update!(state: User::ACTIVATED)
    SecurityLog.create!(user: user, event_type: :user_became_activated)

    if role == :student
      if user.receive_newsletter?
        #TODO: make a prospect instead?
        CreateSalesforceLead.perform_later(user: user)
        SecurityLog.create!(user: user, event_type: :created_salesforce_lead)
      end
    end
  end

end

