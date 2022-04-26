# Changes the passed-in user's state to activated and creates a new Salesforce lead
# No-op if the user is already activated

class ActivateUser

  lev_routine

  protected ###############

  def authorized?
    true
  end

  def exec(user)
    return if user.activated?

    user.update!(state: User::ACTIVATED)

    # create a lead for the user if they are a student and want the newsletter
    # otherwise, the lead gets created at the end of the instructor profile
    if user.role == :student
      user.update!(faculty_status: :no_faculty_info)
      if user.receive_newsletter?
        CreateSalesforceLeadJob.perform_later(user_id: user.id)
      end
    end

    SecurityLog.create!(user: user, event_type: :user_became_activated)
  end

end
