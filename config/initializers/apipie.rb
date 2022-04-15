Apipie.configure do |config|
  config.app_name                = "OpenStax Accounts API"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/api/docs"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
  config.copyright               = "&copy; #{Time.now.year} Rice University"
  config.layout                  = 'application_body_api_docs'
  config.markup                  = MarkdownWrapper.new
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
end
