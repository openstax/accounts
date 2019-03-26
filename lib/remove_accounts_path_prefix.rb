class RemoveAccountsPathPrefix
  def initialize(app, options = {})
    @app = app
  end

  def call(env)
    env['PATH_INFO'].gsub!(/^\/accounts/,'') if 'GET' == env['REQUEST_METHOD'] && env['PATH_INFO'].present?
    @app.call(env)
  end
end