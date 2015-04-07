class FinishUserCreation

  lev_routine

  protected

  def exec(user)
    return if user.is_activated?

    person = Person.create

    transfer_errors_from(person, {type: :verbatim})

    user.person_id = person.id
    user.state     = 'activated'
    user.save

    transfer_errors_from(user, {type: :verbatim})
  end

end
