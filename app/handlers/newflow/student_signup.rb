module Newflow
  class StudentSignup < UserSignup
    lev_handler
    uses_routine AgreeToTerms

    paramify :signup do
      UserSignup.include_common_params_in(self)
    end

    protected #################

    def authorized?
      true
    end

    def required_params
      @required_params ||= [:email, :first_name, :last_name, :password, :role]
    end

    def handle
      super
    end
  end
end
