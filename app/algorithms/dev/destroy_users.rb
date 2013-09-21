module Dev
  class DestroyUsers

    include Lev::Algorithm

  protected

    def exec(users)
      users = users.all if users.is_a? ActiveRecord::Relation
      users = [users].flatten.compact
      users.each {|user| DestroyUser.new.ignore_error(:cannot_destroy_non_temp_user).call(user)}
    end

  end
end