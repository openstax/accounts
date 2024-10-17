# Creates a separate cookie jar on top of Rails' internal ones
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb
class SsoCookieJar < ActionDispatch::Cookies::AbstractCookieJar
  secrets = Rails.application.secrets.sso[:cookie]
  @@cookie_name = secrets[:name]
  @@cookie_options = secrets[:options]

  def subject
    cookie = self[@@cookie_name]
    cookie.symbolize_keys[:sub] unless cookie.nil?
  end

  def subject=(subject)
    permanent[@@cookie_name] = { value: { sub: subject } }
  end

  def delete(options = {})
    @parent_jar.delete @@cookie_name, options.reverse_merge(@@cookie_options)
  end

  def parse(name, data, purpose: nil)
    SsoCookie.read data
  end

  def commit(name, options)
    options[:value] = SsoCookie.generate options
    options.reverse_merge! @@cookie_options
  end
end

ActionDispatch::Cookies::ChainedCookieJars.module_exec do
  def sso
    @sso ||= SsoCookieJar.new(self)
  end
end
