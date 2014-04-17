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
  # show
  ###############################################################

  api :GET, '/application_users/:id', 'Gets the specified ApplicationUser.'
  description <<-EOS
    Gets an ApplicationUser by id.

    #{json_schema(Api::V1::ApplicationUserRepresenter, include: :readable)}
  EOS
  def show
    standard_read(ApplicationUser, params[:id])
  end

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

  api :PUT, '/application_users/:id', 'Updates the specified ApplicationUser.'
  description <<-EOS
    Updates the specified ApplicationUser.

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
