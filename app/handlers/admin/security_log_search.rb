module Admin
  class SecurityLogSearch

    lev_handler transaction: :no_transaction

    paramify :search do
      attribute :query, type: String
      attribute :page, type: Integer
      attribute :per_page, type: Integer
    end

    uses_routine Admin::SearchSecurityLog,
                 as: :search_log,
                 translations: { outputs: {type: :verbatim} }

    protected

    def authorized?
      !Rails.env.production? || caller.is_administrator?
    end

    def handle
      outputs[:query] = search_params.query
      outputs[:page] = search_params.page || 0
      outputs[:per_page] = search_params.per_page || 50
      run(:search_log, outputs[:query], page: outputs[:page], per_page: outputs[:per_page])
    end

  end
end
