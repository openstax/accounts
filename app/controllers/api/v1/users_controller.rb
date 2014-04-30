class Api::V1::UsersController < OpenStax::Api::V1::ApiController

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

      Users have the following attributes:
      String: username, first_name, last_name, full_name, title
      Boolean: is_administrator
    EOS
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
    OSU::AccessPolicy.require_action_allowed!(:read, current_user,
                                              current_user.human_user)
    respond_with current_user.human_user
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
    raise SecurityTransgression unless current_user.human_user
    standard_update(User, current_user.human_user.id)
  end

end