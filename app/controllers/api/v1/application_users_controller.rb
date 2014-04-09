class Api::V1::ApplicationUsersController < Api::V1::OauthBasedApiController
  
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

  api :GET, '/application_users/:id', 'Gets the specified ApplicationUser'
  description <<-EOS
    #{json_schema(Api::V1::ApplicationUserRepresenter, include: :readable)}
  EOS
  def show
    standard_read(ApplicationUser, params[:id])
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/users/:user_id/application_users/', 'Creates a new ApplicationUser. Can only be called by an application.'
  param :user_id, :number, required: true, desc: <<-EOS
    The ID of the user to which the new ApplicationUser should be associated.
  EOS
  description <<-EOS
    Lets a caller application create a new ApplicationUser.

    #{json_schema(Api::V1::ApplicationUserRepresenter, include: [:writeable])}
  EOS
  def create
    @application_user = ApplicationUser.new
    user = User.find(params[:user_id])
    
    ApplicationUser.transaction do
      consume!(@application_user)
      @application_user.application = current_user.application
      @application_user.user = user
      raise SecurityTransgression unless current_user.can_create?(@application_user)
    end
    
    if @application_user.save
      respond_with @application_user, represent_with: Api::V1::ApplicationUserRepresenter, status: :created
      else
      render json: @application_user.errors, status: :unprocessable_entity
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/application_users/:id', 'Updates the specified ApplicationUser'
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

  api :DELETE, '/application_users/:id', 'Deletes the specified ApplicationUser'
  description <<-EOS
    Deletes the specified ApplicationUser.
  EOS
  def destroy
    standard_destroy(ApplicationUser, params[:id])
  end
end
