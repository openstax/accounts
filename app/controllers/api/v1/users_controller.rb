class Api::V1::UsersController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a user of OpenStax'
    description <<-EOS
      All actions in this controller operate only on the current user,
      who is determined from the Oauth token.

      All users of OpenStax have an associated User object.
      Admins (for Accounts only) are identified by the is_administrator boolean.
      Some additional user information can be found in associations, such as
      email addresses in ContactInfos and the password hash in Identity.

      Users have the following String attributes:
      username, first_name, last_name, title, suffix
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/users',
            'Returns a set of Users matching query terms'
  description <<-EOS
    Accepts a query string along with options and returns a JSON representation
    of the matching Users. The maximum number of results is limited to
    #{SearchUsers::MAX_MATCHING_USERS}. If this number is exceeded, an empty
    result set will be returned, although the API will still indicate the number
    of matching users. The schema for the returned JSON result is shown below.

    #{json_schema(Api::V1::UserSearchRepresenter, include: :readable)}
  EOS
  # Using route helpers doesn't work in test or production, probably has to do with initialization order
  example "#{api_example(url_base: 'https://accounts.openstax.org/api/users', url_end: '?q=username:bob%20name=Jones')}"
  param :q, String, required: true, desc: <<-EOS
    The search query string, built up as a space-separated collection of
    search conditions on different fields.  Each condition is formatted as
    "field_name:comma-separated-values".  The resulting list of Users will
    match all of the conditions (boolean 'and').  Each condition will produce
    a list of that must match any of the comma-separated-values (boolean 'or').
    The fields_names and their characteristics are given below.
    When a field is listed as using wildcard matching, it means that any fields
    that start with a comma-separated-value will be matched.

    * `username` &ndash; Matches usernames. (uses wildcard matching)
    * `first_name` &ndash; Matches Users' first names, case insensitive. (uses wildcard matching)
    * `last_name` &ndash; Matches Users' last names, case insensitive. (uses wildcard matching)
    * `name` &ndash; Matches Users' first, last, or full names, case insensitive. (uses wildcard matching)
    * `id` &ndash; Matches Users' IDs exactly.
    * `email` &ndash; Matches Users' emails exactly.
    * `uuid` &ndash; Mathces Users' UUIDs exactly.

    You can also add search terms without prefixes, separated by spaces.

    If there are two uprefixed search terms, they will be treated as
    a search for (first-name AND last-name). Each name will use wildcard matches,
    but they both must match.

    If more or less than two words are given, the terms  will be searched for in all of
    the prefix categories and any matching Users will be returned.

    When combined with prefixed search terms, the final result will contain
    Users matching any of the non-prefixed terms and all of the prefixed terms.

    Examples:

    `username:ric` &ndash; returns Users for 'richb' and 'ricardo' Users.

    `username:ric name:"Van Buren"` &ndash; returns the Users for the 'Ricardo Van Buren' User.

    `j son` &ndash; returns Users for 'Jimmy Richardson', 'James Sonny', and 'Jenny Sonders', but not "Bob Richardson" Users.

    `ric` &ndash; returns Users for 'richb', 'ricardo', and 'Jimmy Rich' Users.
  EOS
  param :order_by, String, desc: <<-EOS
    A string that indicates how to sort the results of the query. The string
    is a comma-separated list of fields with an optional sort direction. The
    sort will be performed in the order the fields are given.
    The fields can be one of #{SearchUsers::SORTABLE_FIELDS.collect{|sf| "`"+sf+"`"}.join(', ')}.
    Sort directions can either be `ASC` for an ascending sort, or `DESC` for a
    descending sort. If not provided, an ascending sort is assumed. Sort directions
    should be separated from the fields by a space. (default: `username ASC`)

    Example:

    `last_name, username DESC` &ndash; sorts by last name ascending, then by username descending
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:search, current_api_user, User)
    query = params[:q]
    options = params.permit(:order_by)
    outputs = SearchUsers.call(query, options).outputs
    respond_with outputs, represent_with: Api::V1::UserSearchRepresenter,
                          location: nil,
                          user_options: {
                            include_private_data: current_application.try(:can_access_private_user_data?)
                          }
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/user', 'Gets the current user\'s data.'
  description <<-EOS
    Returns the current user's data.

    #{json_schema(Api::V1::UserRepresenter, include: :readable)}
  EOS
  def show
    ScoutHelper.ignore!(0.999)

    OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, current_human_user)

    SetGdprData.call(user: current_human_user,
                     headers: request.headers,
                     session: session,
                     ip: ENV['IP_ADDRESS_FOR_GDPR'] || request.ip)

    respond_with current_human_user,
                 represent_with: Api::V1::UserRepresenter,
                 user_options: { include_private_data: true },
                 location: nil
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/user', 'Updates the current user\'s data.'
  description <<-EOS
    Updates the current user's data.

    Note that contained properties (e.g. ContactInfos) can be read
    but cannot be updated through this method. To update these
    nested properties, use their REST API methods.

    #{json_schema(Api::V1::UserRepresenter, include: [:writeable])}
  EOS
  def update
    raise SecurityTransgression unless current_human_user
    security_log :user_updated, user_params: JSON.parse(request.body.read)
    request.body.rewind
    standard_update(User.find(current_human_user.id))
  end

end
