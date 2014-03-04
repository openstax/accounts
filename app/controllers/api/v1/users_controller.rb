class Api::V1::UsersController < Api::V1::OauthBasedApiController

  include OSU::Roar

  doorkeeper_for :all

  resource_description do
    api_versions "v1"
    short_description 'TBD'
    description <<-EOS
      TBD
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/users/:id', 'Gets the specified User'
  description <<-EOS
    #{json_schema(Api::V1::UserRepresenter, include: :readable)}            
  EOS
  def show
    rest_get(User, params[:id])
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/users/:id', 'Updates the specified User'
  description <<-EOS
    Lets a caller update a User record.  Note that contained properties (e.g.
    ContactInfos) can be read but cannot be updated through this method.  To
    update these nested properties use their REST API methods.

    #{json_schema(Api::V1::UserRepresenter, include: [:writeable])}            
  EOS
  def update
    rest_update(User, params[:id])
  end

  ###############################################################
  # search
  ###############################################################

  api :GET, '/users/search', 'Return a set of Users matching query terms'
  description <<-EOS
    Accepts a query string along with options and returns a JSON representation
    of the matching Users.  Some User data may be filtered out depending on the
    caller's status and priviledges in the system.  The schema for the returned
    JSON result is shown below. 

    <p>Currently, access to this API is limited to trusted applications where the 
    application is making the API call on its own behalf, not on the behalf of
    a user.</p>

    #{json_schema(Api::V1::UserSearchRepresenter, include: :readable)}            
  EOS
  example "#{Rails.application.routes.url_helpers.search_api_users_url}/?q=username:bob%20name=Jones" if !Rails.env.test?
  param :q, String, required: true, desc: <<-EOS
    The search query string, built up as a space-separated collection of
    search conditions on different fields.  Each condition is formatted as
    "field_name:comma-separated-values".  The resulting list of users will
    match all of the conditions (boolean 'and').  Each condition will produce
    a list of users where those users must match any of the comma-separated-values
    (boolean 'or').  The fields_names and their characteristics are given below.
    When a field is listed as using wildcard matching, it means that any fields
    that start with a comma-separated-value will be matched.

    * `username` &ndash; Matches users' usernames.  Any characters not allowed in valid 
                 usernames will be discarded. (uses wildcard matching)
    * `first_name` &ndash; Matches users' first names. Any characters matching `/[^A-Za-z ']/` 
                   will be discarded. (uses wildcard matching)
    * `last_name` &ndash; Matches users' last names. Any characters matching `/[^A-Za-z ']/` 
                  will be discarded. (uses wildcard matching)
    * `name` &ndash; Matches users' first, last, or full names. Any characters matching `/[^A-Za-z ']/` 
             will be discarded. (uses wildcard matching)
    * `id` &ndash; Matches users' IDs exactly.
    * `email` &ndash; Matches users' emails exactly.

    Examples:

    `username:ric` &ndash; returns 'richb' and 'ricardo' users.

    `username:ric name:"Van Buren"` &ndash; returns the 'Ricardo Van Buren' user.
  EOS
  param :page, Integer, desc: <<-EOS
    Specifies the page of results to retrieve, zero-indexed. (default: 0)
  EOS
  param :per_page, Integer, desc: <<-EOS
    The number of users to retrieve on the chosen page. (default: 20)
  EOS
  param :order_by, String, desc: <<-EOS
    A string that indicates how to sort the results of the query.  The string
    is a comma-separated list of fields with an optional sort direction.  The
    sort will be performed in the order the fields are given.  
    The fields can be one of #{Api::V1::SearchUsers::SORTABLE_FIELDS.collect{|sf| "`"+sf+"`"}.join(', ')}.
    Sort directions can either be `ASC` for 
    an ascending sort, or `DESC` for a
    descending sort.  If not provided an ascending sort is assumed. Sort directions
    should be separated from the fields by a space. (default: `username ASC`)

    Example:

    `last_name, username DESC` &ndash; sorts by last name ascending, then by username descending 
  EOS
  def search
    AccessPolicy.require_action_allowed!(:search, current_user, User)
    outputs = SearchUsers.call(params[:q], params.slice(:page, :per_page, :order_by)).outputs
    respond_with outputs, represent_with: Api::V1::UserSearchRepresenter
  end

end