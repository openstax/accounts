class Api::V1::UsersController < Api::V1::ApiController
  # New tokens last 1 day
  SSO_TOKEN_INITIAL_DURATION = 24.hours
  # Ensure any returned tokens last for at least 12 more hours
  SSO_TOKEN_MIN_DURATION = 12.hours

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
    * `uuid` &ndash; Matches Users' UUIDs exactly.
    * `external_id` &ndash; Matches Users' external IDs exactly.

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
    For users that are not logged in, a 403 forbidden response is normally returned.
    However, if always_200 is set to true, then a 200 OK with a blank object is returned instead.

    #{json_schema(Api::V1::UserRepresenter, include: :readable)}
  EOS
  def show
    begin
      OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, current_human_user)
    rescue SecurityTransgression => error
      return render(plain: {}) if params[:always_200] == 'true'
      raise error
    end

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

  ###############################################################
  # find
  ###############################################################

  api :POST, '/user/find', 'Finds a user account.'
  description <<-EOS
    Finds a user.

    An external_id must be supplied.

    If the external_id is already in use, that existing user will be returned.
    If the sso parameter is also set, an SSO token for the user will also be returned.

    Otherwise, a 404 error is returned.

    #{json_schema(Api::V1::FindUserRepresenter, include: [:readable, :writable])}
  EOS
  def find
    OSU::AccessPolicy.require_action_allowed!(:find, current_api_user, User)
    # OpenStax::Api#standard_(update|create) require an ActiveRecord model, which we don't have
    # Substitue a Hashie::Mash to read the JSON encoded body
    payload = consume!(Hashie::Mash.new, represent_with: Api::V1::FindUserRepresenter)

    user = if payload.external_id.present?
      User.joins(:external_ids).find_by!(external_ids: { external_id: payload.external_id })
    elsif payload.uuid.present?
      User.find_by!(uuid: payload.uuid)
    else
      raise ActiveRecord::RecordNotFound, 'either external_id or uuid must be provided'
    end

    token = get_sso_token(current_api_user.application, user) if payload.sso.present?

    respond_with user, represent_with: Api::V1::FindUserRepresenter,
                       status: :ok,
                       location: nil,
                       user_options: { sso: token }
  end

  ###############################################################
  # find_or_create
  ###############################################################

  api :POST, '/user/find-or-create', 'Finds or Creates a user account.'
  description <<-EOS
    Either finds or creates a new user. If a new user is created, its
    state will be "unclaimed" meaning it is a place-holder account for
    an user who has not yet completed the sign up process.

    An email address, username or external_id must be supplied.

    If the username, email or external_id is already in use, that existing user's ID
    will be returned.

    If an account is created with no username, it cannot be logged
    into directly. It will merged with the user's account when they complete the
    standard sign up process using a matching email address.

    If an account is created with a username and password, it may be signed into and used
    immediately once the user agress to the Terms and Conditions.

    #{json_schema(Api::V1::FindOrCreateUserRepresenter, include: [:readable, :writable])}
  EOS
  def find_or_create
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, User)
    # OpenStax::Api#standard_(update|create) require an ActiveRecord model, which we don't have
    # Substitute a Hashie::Mash to read the JSON encoded body
    payload = consume!(Hashie::Mash.new, represent_with: Api::V1::FindOrCreateUserRepresenter)
    payload.application = current_api_user.application

    result = FindOrCreateUser.call(payload.except(:sso))
    if result.errors.any?
      render json: { errors: result.errors }, status: :conflict
    else
      token = get_sso_token(payload.application, result.outputs.user) if payload.sso.present?

      respond_with result.outputs.user, represent_with: Api::V1::FindOrCreateUserRepresenter,
                                        location: nil,
                                        user_options: { sso: token }
    end
  end

  ###############################################################
  # external_id
  ###############################################################

  api :POST, '/user/external-ids', 'Creates an external id for a given user.'
  description <<-EOS
    Creates an external id for a given user.

    Both external_id and user_id must be supplied.

    Only trusted apps may call this API. All others will receive a 403 error.

    If the external_id does not exist, it is created.

    Whether or not it is created, 201 is returned.

    #{json_schema(Api::V1::ExternalIdRepresenter, include: [:readable, :writable])}
  EOS
  def create_external_id
    model = ExternalId.new
    consume! model

    OSU::AccessPolicy.require_action_allowed! :create, current_api_user, model

    if model.valid?
      ExternalId.import [ model ], on_duplicate_key_ignore: true
    elsif model.errors.any? { |e| e.type != :taken }
      return render_api_errors(model.errors)
    end

    # Successful import or model already exists
    respond_with model, { status: :created, location: nil }
  end

  private

  def get_sso_token(application, user)
    access_token = Doorkeeper::AccessToken.find_or_create_for(
      application: application,
      resource_owner: user,
      scopes: Doorkeeper.config.default_scopes,
      expires_in: SSO_TOKEN_INITIAL_DURATION,
      use_refresh_token: false,
    )

    return access_token.token if access_token.created_at > user.updated_at &&
                                 access_token.revoked_at.nil? && (
                                   access_token.expires_at.nil? ||
                                   access_token.expires_at >= Time.current + SSO_TOKEN_MIN_DURATION
                                 )

    access_token = Doorkeeper::AccessToken.create_for(
      application: application,
      resource_owner: user,
      scopes: Doorkeeper.config.default_scopes,
      expires_in: SSO_TOKEN_INITIAL_DURATION,
      use_refresh_token: false
    )

    access_token.token
  end

end
