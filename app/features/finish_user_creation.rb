

class FinishUserCreation

  include Feature

  def exec(user)
    return if user.person.present?

    person = Person.create
    user.update_attribute(:person_id, person.id)
  end

end