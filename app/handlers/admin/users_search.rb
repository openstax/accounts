module Admin
  class UsersSearch

    lev_handler transaction: :no_transaction
    
    paramify :search do
      attribute :terms, type: String
      attribute :page, type: Integer
    end

    uses_routine Admin::SearchUsers,
                 as: :search_users,
                 translations: { outputs: {type: :verbatim} }

    protected

    def authorized?
      !Rails.env.production? || caller.is_administrator?
    end

    def handle
      outputs[:query] = search_params.terms
      outputs[:page] = search_params.page || 0
      outputs[:per_page] = 20
      run(:search_users, outputs[:query], page: outputs[:page])
    end

  end
end
