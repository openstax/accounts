module Admin
  class UsersSearch

    lev_handler transaction: :no_transaction
    
    paramify :search do
      attribute :terms, type: String
      attribute :page, type: Integer
    end

    uses_routine SearchUsers,
                 as: :search_users,
                 translations: { outputs: {type: :verbatim} }

  protected

    def authorized?
      !Rails.env.production? || caller.is_admin?
    end

    def handle
      run(:search_users, search_params.terms, page: search_params.page || 0)
    end

  end
end
