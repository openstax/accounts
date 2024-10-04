# Use the ExceptionsController to rescue routing/bad request exceptions
# https://coderwall.com/p/w3ghqq/rails-3-2-error-handling-with-exceptions_app
Rails.application.config.exceptions_app = ->(env) {
  ExceptionsController.action(:rescue_from).call(env)
}
