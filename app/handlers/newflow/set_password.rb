module Newflow
  class SetPassword
    lev_handler
    uses_routine ::SetPassword

    paramify :setup_password_form do
      attribute :password
      validates :password, presence: true
    end

    protected #################

    def setup
      @user = options[:user]
    end

    def authorized?
      !@user.is_anonymous?
    end

    def handle
      run(
        ::SetPassword,
        user: @user,
        password: setup_password_form_params.password,
        password_confirmation: setup_password_form_params.password
      )
    end
  end
end
