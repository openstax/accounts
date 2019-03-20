class RecodeUrl
  def initialize(app, options = {})
    @app = app
  end
  
  def call(env)
    env['PATH_INFO'] = env['PATH_INFO'].gsub('/accounts','') if env['REQUEST_METHOD'] == 'GET'
    @app.call(env)
  end
end