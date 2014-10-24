class FinishUserCreation

  lev_routine

  protected

  def exec(user)
    return if !user.is_temp

    person = Person.create

    transfer_errors_from(person, {type: :verbatim})

    user.person_id = person.id
    user.is_temp   = false
    user.save

    transfer_errors_from(user, {type: :verbatim})
  end

end