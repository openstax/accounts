ActionInterceptor.configure do |config|
  # default_strategies
  # Type: Array
  # Array of the default strategies used to store and retrieve url's.
  # When storing a url, all strategies will be used.
  # When attempting to retrieve stored url's, strategies will be called
  # in order until one of them returns a non-blank string.
  # Available strategies: :session
  # Default: [ :session ]
  config.default_strategies = [ :session ]

  # default_url
  # Type: String
  # If no stored url is found, or if the stored url would cause a self redirect,
  # controller methods will use (redirect to) this url instead.
  # Default: nil (root_url)
  config.default_url = nil

  # default_key
  # Type: Symbol
  # The default key under which url's are stored in the session.
  # Used if the :key option is not provided when storing or retrieving url's.
  # Default: :r
  config.default_key = :return_to
end
