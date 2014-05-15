ActionInterceptor.configure do
  # intercepted_url_key(key)
  # Type: Method
  # Arguments: the key (Symbol)
  # The parameter/session variable that will hold the intercepted URL
  # Default: :r
  intercepted_url_key :return_to

  # interceptor(interceptor_name, &block)
  # Type: Method
  # Arguments: interceptor name (Symbol or String),
  #            &block (Proc)
  # Defines an interceptor
  # Default: none
  # Example: interceptor :my_name do
  #            redirect_to my_action_users_url if some_condition
  #          end
  #
  #          (Conditionally redirects to :my_action in UsersController)
  interceptor :registration do
    redirect_to register_path if current_user.is_temp?
  end

  interceptor :expired_password do
    return unless current_user.identity.try(:should_reset_password?)
    identity = current_user.identity
    identity.generate_reset_code
    redirect_to reset_password_path(code: identity.reset_code)
  end
end
