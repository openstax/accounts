module Newflow
  class CreatePassword
    lev_handler
    uses_routine ::SetPassword

    paramify :create_password_form do
      attribute :password
      validates :password, presence: true
    end

    protected #################

    def setup
      @user = caller
    end

    def authorized?
      !@user.is_anonymous?
    end

    def handle
      run(
        ::SetPassword,
        user: @user,
        password: create_password_form_params.password,
        password_confirmation: create_password_form_params.password
      )

      outputs.user = @user
    end
  end
end
