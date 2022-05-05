FinePrint.configure do |config|
  # Layout to be used for FinePrint's controllers
  # Default: 'application'
  config.layout = 'admin'

  # Array of custom helpers for FinePrint's controllers
  config.helpers = []

  # Proc called with a controller as self. Returns the current user.
  config.current_user_proc = lambda { respond_to?(:current_human_user) ? \
                                      current_human_user : current_user }

  # This proc is called when a user tries to access FinePrint's controllers.
  # Should raise and exception, render or redirect unless the user is a manager
  # or admin.
  config.authenticate_manager_proc = lambda { |user| (!user.nil? && \
                                                     user.is_administrator?) || \
                                                     head(:forbidden) }

  # This proc is called before FinePrint determines if contracts need to be
  # signed. If it returns true, FinePrint will proceed with its checks and
  # potentially call the redirect_to_contracts_proc with the user as argument.
  # If it returns false, renders or redirects, FinePrint will stop its checks.
  config.authenticate_user_proc = lambda { |user|
    !user.nil? && !user.is_anonymous?
  }

  # Controller Configuration
  # Can be set in this initializer or passed as options to `fine_print_require`

  # This proc is called when a user tries to access a resource protected by FinePrint,
  # but has not signed all the required contracts. Should redirect the user, render or raise an exception.
  # The `contracts` argument contains the contracts that need to be signed.
  # The default redirects users to FinePrint's contract signing views.
  # The `fine_print_return` method can be used to return from this redirect.
  config.redirect_to_contracts_proc = lambda { |user, contracts|
    redirect_to main_app.pose_terms_path(terms: contracts)
  }
end
