# Provides a separate CookieJar for the SSO cookie, with a different secret_token
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb
class SsoCookieJar < ActionDispatch::Cookies::CookieJar
  def self.build(request)
    # We will need a new strategy in Rails 5, since the key generator will no longer be stored
    # when the CookieJar is built and will instead be loaded directly from the Request object
    previous_key_generator = request.env[ActionDispatch::Cookies::GENERATOR_KEY]

    begin
      request.env[ActionDispatch::Cookies::GENERATOR_KEY] = Rails.application.sso_key_generator
      super(request)
    ensure
      request.env[ActionDispatch::Cookies::GENERATOR_KEY] = previous_key_generator
    end
  end
end

ActionDispatch::Request.class_exec do
  # Rails 4:
  def have_cookie_jar?
    env.key? "action_dispatch.cookies".freeze
  end

  def have_sso_cookie_jar?
    env.key? "action_dispatch.sso_cookies".freeze
  end

  def sso_cookie_jar
    env["action_dispatch.sso_cookies".freeze] ||= SsoCookieJar.build(self)
  end

  # Rails 5:
  #def have_sso_cookie_jar?
  #  has_header? "action_dispatch.sso_cookies".freeze
  #end
  #
  #def sso_cookie_jar=(jar)
  #  set_header "action_dispatch.sso_cookies".freeze, jar
  #end
  #
  #def sso_cookie_jar
  #  fetch_header("action_dispatch.sso_cookies".freeze) do
  #    self.sso_cookie_jar = SsoCookieJar.build(self, cookies)
  #  end
  #end
end

ActionDispatch::Cookies.class_exec do
  def call(env)
    request = ActionDispatch::Request.new env

    status, headers, body = @app.call(env)

    if request.have_cookie_jar?
      cookie_jar = request.cookie_jar
      cookie_jar.write(headers) unless cookie_jar.committed?
    end

    if request.have_sso_cookie_jar?
      cookie_jar = request.sso_cookie_jar
      cookie_jar.write(headers) unless cookie_jar.committed?
    end

    if headers[ActionDispatch::Cookies::HTTP_HEADER].respond_to?(:join)
      headers[ActionDispatch::Cookies::HTTP_HEADER] =
        headers[ActionDispatch::Cookies::HTTP_HEADER].join("\n")
    end

    [status, headers, body]
  end
end
