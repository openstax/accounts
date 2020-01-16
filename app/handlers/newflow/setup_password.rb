module Newflow
  class SetupPassword
    lev_handler

    paramify :setup_password_form do
      attribute :password
      validates :password, presence: true
    end

    protected #################

    def setup
      @user = options[:user]
    end

    def authorized?
      Identity.where(user: user).none?
    end

    def handle
      create_identity
      create_authentication
    end

    def create_identity
      @identity = Identity.create(
        password: setup_password_form_params.password,
        password_confirmation: setup_password_form_params.password,
        user: @user
      )
      transfer_errors_from(@identity, { scope: :password }, :fail_if_errors)
    end

    def create_authentication
      @authentication = Authentication.create(
        provider: 'identity',
        user_id: @user.id, uid: @user.identity.id
      )
      transfer_errors_from(@authentication, { scope: :email }, :fail_if_errors)
    end
  end
end
