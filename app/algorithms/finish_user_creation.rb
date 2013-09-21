

class FinishUserCreation

  include Lev::Algorithm

protected

  def exec(user)
    return if !user.is_temp

    person = Person.create
    user.save do |uu|
      uu.person_id = person.id
      uu.is_temp = false
    end
  end

end