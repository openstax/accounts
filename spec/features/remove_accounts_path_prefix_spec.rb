require 'rails_helper'

# OpenStax::PathPrefixer::Middleware strips the "/accounts" prefix from PATH_INFO and
# moves it to SCRIPT_NAME before the router runs, so prefix handling is two separable
# things: the middleware rewriting the env, and the router dispatching what's left.
#
# This replaced `expect_any_instance_of(SomeController).to receive(:action)` over a raw
# Rack::MockRequest. Asserting that a controller method was called fails for any reason
# the action isn't reached -- authentication, a redirect, a middleware short-circuit --
# and reports it as "Exactly one instance should have received the following message(s)
# but didn't", which says nothing about routing. It was also this suite's
# longest-standing intermittent failure.
describe 'Remove accounts path prefix' do
  # PATH_INFO from env_for can be frozen; the middleware rewrites it with gsub!, which
  # the real server's unfrozen string tolerates.
  def env_after_middleware(path)
    env = Rack::MockRequest.env_for(path)
    env['PATH_INFO'] = env['PATH_INFO'].dup
    OpenStax::PathPrefixer::Middleware.new(->(_) { [200, {}, []] }).call(env)
    env
  end

  def route_for(prefixed_path)
    Rails.application.routes.recognize_path(
      env_after_middleware(prefixed_path)['PATH_INFO'], method: :get
    )
  end

  describe 'the middleware' do
    it 'moves the prefix into SCRIPT_NAME so url helpers re-add it' do
      env = env_after_middleware('/accounts/i/signup')

      expect(env['PATH_INFO']).to eq('/i/signup')
      expect(env['SCRIPT_NAME']).to eq('/accounts')
    end

    it 'strips a bare prefix' do
      expect(env_after_middleware('/accounts')['PATH_INFO']).to eq('')
    end

    it 'leaves an unprefixed path alone' do
      env = env_after_middleware('/i/signup')

      expect(env['PATH_INFO']).to eq('/i/signup')
      expect(env['SCRIPT_NAME']).to eq('')
    end

    it 'does not strip a path that merely starts with the prefix text' do
      expect(env_after_middleware('/accountsomething')['PATH_INFO']).to eq('/accountsomething')
    end
  end

  describe 'the remaining path routes to the right controller' do
    it 'routes the API user endpoint' do
      expect(route_for('/accounts/api/user'))
        .to include(controller: 'api/v1/users', action: 'show')
    end

    it 'routes the home page' do
      expect(route_for('/accounts/')).to include(controller: 'static_pages', action: 'home')
    end

    it 'routes newflow signup' do
      expect(route_for('/accounts/i/signup'))
        .to include(controller: 'newflow/signup', action: 'welcome')
    end
  end

  describe 'redirects keep the prefix' do
    let(:request) { Rack::MockRequest.new(Rails.application) }

    it 'sends the home page to the login page' do
      expect(URI(request.get('/accounts').location).path).to eq('/accounts/i/login')
    end

    it 'sends legacy signup to newflow signup' do
      response = request.get('/accounts/signup')

      expect(response.get_header('Location')).to end_with('/accounts/i/signup')
    end
  end
end
