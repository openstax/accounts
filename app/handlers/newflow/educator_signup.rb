module Newflow
  class EducatorSignup < UserSignup
    lev_handler

    paramify :signup do
      UserSignup.include_common_params_in(self)
    end

    protected #################

    def authorized?
      true
    end

    def required_params
      [:email, :first_name, :last_name, :password, :phone_number]
    end

    def handle
      super
    end
  end
end
