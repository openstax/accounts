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
    user = (request.format == :json) ? current_human_user : current_user
    return unless user.try(:is_temp?)

    respond_to do |format|
      format.html { redirect_to register_path }
      format.json { head(:forbidden) }
    end
  end

  interceptor :expired_password do
    user = (request.format == :json) ? current_human_user : current_user
    identity = user.try(:identity)
    return unless identity.try(:should_reset_password?)

    code_hash = {code: identity.generate_reset_code}

    respond_to do |format|
      format.html { redirect_to reset_password_path(code_hash) }
      # If we do this check (we probably should), then clients of the API
      # must handle this response and redirect the user appropriately.
      format.json { render :json => {expired_password: code_hash}.to_json }
    end
  end
end
