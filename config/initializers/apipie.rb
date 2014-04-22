Apipie.configure do |config|
  config.app_name                = "#{SITE_NAME} API"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/api/docs"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
  config.copyright               = OpenStax::Utilities::Text.copyright('2013', COPYRIGHT_HOLDER)
  config.layout                  = 'application_body_api_docs'
  config.markup                  = Apipie::Markup::Markdown.new
  config.namespaced_resources    = false
  config.default_version         = 'v1'
  config.link_extension          = ''
  config.app_info =              <<-eos
    Access to the API must be achieved through an OAuth flow or by having a user
    that is logged in to the system (with a session, etc).

    When communicating with the API, developers must set a header in the HTTP request to specify
    which version of the API they want to use:

    <table class='std-list-1' style='width: 80%; margin: 15px auto'>
      <tr>
        <th>Header Name</th>
        <th>Value</th>
        <th>Version Accessed</th>
      </tr>
      <tr>
        <td><code>'Accept'</code></td>
        <td><code>'application/vnd.accounts.openstax.v1'</code></td>
        <td>v1</td>
      </tr>
    </table>

    Many of the API specifications provide a related JSON schema.  These schemas are based on the 
    standard being defined at [http://json-schema.org/](http://json-schema.org/).  A lot of these
    times these schemas aren't overly specific to the actions they are listed under, e.g. they 
    always say that an `id` is required but that isn't the case when new data is being posted to
    a `create` call.
  eos
  # Ok this is one of the uglier things I have ever done in code.  To get Apipie to 
  # render nicely inside the layout specified above, it needs to know about some helper
  # methods used in that layout.  It would seem that to tell the Apipie controllers about
  # these helper methods would be as simple as extending the ApipiesController as in:
  #
  #   Apipie::ApipiesController.class_eval do
  #     helper_method :current_user, :current_user=, :signed_in?, :sign_in, :sign_out!
  #   end
  #
  # Typically we'd put this in an initializer or some lib file.
  #
  # This works except that in development, Apipie reloads a ton of controllers to make
  # sure that generated API documentation reflects the latest changed state of the 
  # application controller code.  If it didn't reload this code, developers would have
  # to restart the server for Apipie to generate updated documentation. When the reload
  # happens, a class_eval call like the one above gets wiped out -- the result is that
  # in development Apipie pages load fine once, but then puke on future loads.  One 
  # hack would be to put the code above in a file that gets reloaded by Apipie (e.g.
  # the ApplicationController); however, this seems to only work on page loads after
  # the first one.  
  #
  # The only real hook we have into Apipie is the authenticate Proc.  We use it here
  # to set the helper_methods if they don't yet exist.  So this hack is ugly because
  # I'm using "authenticate" in a way not intended and I'm using an attribute,
  # "_helper_methods", that appears intended to be private.  In development, the helper
  # methods will never be set, and the class_eval will do it.  In production, they 
  # should be set after the first call.
  #
  # The real solution is to fork Apipie and get it to support helper_method set in 
  # config.  Maybe we'll do that.  I added an issue on Apipie to get the ball rolling:
  # https://github.com/Apipie/apipie-rails/issues/210
  #
  config.authenticate = Proc.new {
    return if self._helper_methods.include?(:current_user)
    class_eval { helper_method :current_user, :current_user=, :signed_in?, :sign_in, :sign_out! }
  }
end
