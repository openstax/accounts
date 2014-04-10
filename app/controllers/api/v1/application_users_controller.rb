class Api::V1::ApplicationUsersController < OpenStax::Api::V1::OauthBasedApiController
  
  doorkeeper_for :all
  
  resource_description do
    api_versions "v1"
    short_description 'Records which users interact with which applications, as well the users'' preferences for each app'
    description <<-EOS
      ApplicationUser records which users have interacted in the past with what OpenStax Accounts applications.
      This information is used to push updates to the user's info to all applications that know that user.
      User preferences for each app are also recorded in ApplicationUser.
      Current preferences include default_contact_info_id, the id of the user's default contact info object to be used for that particular application.'
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/application_users/:id', 'Gets the specified ApplicationUser.'
  description <<-EOS
    #{json_schema(Api::V1::ApplicationUserRepresenter, include: :readable)}
  EOS
  def show
    standard_read(ApplicationUser, params[:id])
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/users/:user_id/application_users/',
      'Creates a new ApplicationUser. Can only be called by an application.'
  param :user_id, :number, required: true, desc: <<-EOS
    The ID of the user to which the new ApplicationUser should be associated.
  EOS
  description <<-EOS
    Lets a caller application create a new ApplicationUser.

    #{json_schema(Api::V1::ApplicationUserRepresenter, include: [:writeable])}
  EOS
  def create
    standard_nested_create(ApplicationUser, :user, params[:user_id]) do |app_user|
      app_user.application = current_user.application
      app_user.user = User.find(params[:user_id])
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/application_users/:id', 'Updates the specified ApplicationUser.'
  description <<-EOS
    Lets a caller update a ApplicationUser record.

    #{json_schema(Api::V1::ApplicationUserRepresenter, include: [:writeable])}
  EOS
  def update
    standard_update(ApplicationUser, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/application_users/:id', 'Deletes the specified ApplicationUser.'
  description <<-EOS
    Deletes the specified ApplicationUser.
  EOS
  def destroy
    standard_destroy(ApplicationUser, params[:id])
  end
end
