module Dev
  class DestroyUsers

    include Lev::Routine

    uses_routine DestroyUser,
                 ignored_errors: [:cannot_destroy_non_temp_user]

  protected

    def exec(users)
      users = users.all if users.is_a? ActiveRecord::Relation
      users = [users].flatten.compact
      users.each {|user| run(DestroyUser, user)}
    end

  end
end