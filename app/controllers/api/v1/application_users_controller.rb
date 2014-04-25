class Api::V1::ApplicationUsersController < OpenStax::Api::V1::ApiController
  
  resource_description do
    api_versions "v1"
    short_description 'Records which users interact with which applications, as well the users'' preferences for each app.'
    description <<-EOS
      ApplicationUser records which users have interacted in the past with what OpenStax Accounts applications.
      This information is used to push updates to the user's info to all applications that know that user.
      User preferences for each app are also recorded in ApplicationUser.
      Current preferences include default_contact_info_id, the id of the user's default contact info object to be used for that particular application.'
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/application_users', 'Return a set of ApplicationUsers matching query terms'
  description <<-EOS
    Accepts a query string along with options and returns a JSON representation
    of the matching ApplicationUsers.  Some User data may be filtered out depending on the
    caller's status and priviledges in the system.  The schema for the returned
    JSON result is shown below.

    #{json_schema(Api::V1::ApplicationUserSearchRepresenter, include: :readable)}
  EOS
  # Using route helpers doesn't work in test or production, probably has to do with initialization order
  example "#{api_example(url_base: 'https://accounts.openstax.org/api/application_users/search', url_end: '?q=username:bob%20name=Jones')}"
  param :q, String, required: true, desc: <<-EOS
    The search query string, built up as a space-separated collection of
    search conditions on different fields.  Each condition is formatted as
    "field_name:comma-separated-values".  The resulting list of ApplicationUsers will
    have Users that match all of the conditions (boolean 'and').  Each condition will produce
    a list of ApplicationUsers whose Users must match any of the comma-separated-values
    (boolean 'or').  The fields_names and their characteristics are given below.
    When a field is listed as using wildcard matching, it means that any fields
    that start with a comma-separated-value will be matched.

    * `username` &ndash; Matches Users' usernames.  Any characters matching
                 `#{ERB::Util.html_escape (User::USERNAME_DISCARDED_CHAR_REGEX.inspect)}`
                 will be discarded. (uses wildcard matching)
    * `first_name` &ndash; Matches Users' first names, case insensitive. (uses wildcard matching)
    * `last_name` &ndash; Matches Users' last names, case insensitive. (uses wildcard matching)
    * `name` &ndash; Matches Users' first, last, or full names, case insenstive. (uses wildcard matching)
    * `id` &ndash; Matches Users' IDs exactly.
    * `email` &ndash; Matches Users' emails exactly.

    You can also add search terms without prefixes, separated by spaces.  These terms  will be searched for
    in all of the prefix categories.  Any ApplicationUsers with matching Users will be returned.
    When combined with prefixed search terms, the final results will contain Users matching any of
    the non-prefixed terms and all of the prefixed terms.

    Examples:

    `username:ric` &ndash; returns ApplicationUsers for 'richb' and 'ricardo' Users.

    `username:ric name:"Van Buren"` &ndash; returns the ApplicationUsers for the 'Ricardo Van Buren' User.

    `ric` &ndash; returns ApplicationUsers for 'richb', 'ricardo', and 'Jimmy Rich' Users.
  EOS
  param :page, Integer, desc: <<-EOS
    Specifies the page of results to retrieve, zero-indexed. (default: 0)
  EOS
  param :per_page, Integer, desc: <<-EOS
    The number of ApplicationUsers to retrieve on the chosen page. (default: 20)
  EOS
  param :order_by, String, desc: <<-EOS
    A string that indicates how to sort the results of the query.  The string
    is a comma-separated list of fields with an optional sort direction.  The
    sort will be performed in the order the fields are given.  
    The fields can be one of #{Api::V1::SearchApplicationUsers::SORTABLE_FIELDS.collect{|sf| "`"+sf+"`"}.join(', ')}.
    Sort directions can either be `ASC` for an ascending sort, or `DESC` for a
    descending sort.  If not provided, an ascending sort is assumed. Sort directions
    should be separated from the fields by a space. (default: `username ASC`)

    Example:

    `last_name, username DESC` &ndash; sorts by last name ascending, then by username descending 
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_user, ApplicationUser)
    options = params.slice(:page, :per_page, :order_by)
    outputs = SearchApplicationUsers.call(current_user.application, params[:q], options).outputs
    respond_with outputs, represent_with: Api::V1::ApplicationUserSearchRepresenter
  end

  ###############################################################
  # show
  ###############################################################

# TODO: Get application and user from token, like create
#api :GET, '/application_users/:id', 'Gets the specified ApplicationUser.'
#description <<-EOS
#  Gets an ApplicationUser by id.

#  #{json_schema(Api::V1::ApplicationUserRepresenter, include: :readable)}
#EOS
#def show
#  standard_read(ApplicationUser, params[:id])
#end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/application_users/', 'Creates an ApplicationUser based on the OAuth access token.'
  description <<-EOS
    Can only be called by an Application representing a User.
    The Application and User in question are determined from the OAuth access token.
    Creates an ApplicationUser for the given Application/User pair.

    #{json_schema(Api::V1::ApplicationUserRepresenter, include: [:writeable])}
  EOS
  def create
    # The AccessPolicy cannot enforce that the application is not nil,
    # but the validation in ApplicationUser should handle this case.
    standard_create(ApplicationUser) do |app_user|
      app_user.application = current_user.application
      app_user.user = current_user.human_user
    end
  end

  ###############################################################
  # update
  ###############################################################

# TODO: Get application and user from token, like create
#api :PUT, '/application_users/:id', 'Updates the specified ApplicationUser.'
#description <<-EOS
#  Updates the specified ApplicationUser.

#  #{json_schema(Api::V1::ApplicationUserRepresenter, include: [:writeable])}
#EOS
#def update
#  standard_update(ApplicationUser, params[:id])
#end

  ###############################################################
  # destroy
  ###############################################################

# TODO: Get application and user from token, like create
#api :DELETE, '/application_users/:id', 'Deletes the specified ApplicationUser.'
#description <<-EOS
#  Deletes the specified ApplicationUser.
#EOS
#def destroy
#  standard_destroy(ApplicationUser, params[:id])
#end

  ###############################################################
  # updated
  ###############################################################

  api :GET, '/application_users/updated',
            'Gets all unread updates for ApplicationUsers that use the current app'
  description <<-EOS
    Returns the ApplicationUser data for Users that use the current application and
    have unread updates for the current app.

    #{json_schema(Api::V1::ApplicationUsersRepresenter, include: :readable)}
  EOS

  api :PUT, '/application_users/updated',
            'Marks ApplicationUser updates as "read"'
  description <<-EOS
    Marks ApplicationUser updates as read for the current app.

    * `application_users` &ndash; Hash containing info about the ApplicationUsers whose updates were read.
                          Keys are ApplicationUser id's. Values are the "unread count" last received for
                          that specific ApplicationUser.
  def updated
    OSU::AccessPolicy.require_action_allowed!(:updated, current_user, ApplicationUser)
    if request.get?
      outputs = ApplicationUsersUpdated.call(current_user.application).outputs
      respond_with outputs[:application_users], represent_with: Api::V1::ApplicationUsersRepresenter
    elsif request.put?
      outputs = MarkApplicationUsersAsRead.call(params[:application_users]).outputs
      respond_with outputs[:response]
    end
  end

end
