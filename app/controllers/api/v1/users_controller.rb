class Api::V1::UsersController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'TBD'
    description <<-EOS
      TBD
    EOS
  end

  ###############################################################
  # me
  ###############################################################

  api :GET, '/users/me', 'Gets the current user\'s User data'
  description <<-EOS
    Returns the current user's User data.  If there is no current
    user (e.g. if this is an application-to-application call) an
    error will be raised.

    #{json_schema(Api::V1::UserRepresenter, include: :readable)}            
  EOS
  def me
    raise SecurityTransgression unless current_user.human_user && !current_user.human_user.is_anonymous?
    respond_with current_user.human_user
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/users/:id', 'Gets the specified User'
  description <<-EOS
    #{json_schema(Api::V1::UserRepresenter, include: :readable)}            
  EOS
  def show
    standard_read(User, params[:id])
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
    standard_update(User, params[:id])
  end

end