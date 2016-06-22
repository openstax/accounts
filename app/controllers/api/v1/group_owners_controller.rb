class Api::V1::GroupOwnersController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group owner.'
    description <<-EOS
      GroupOwners represent owners of a Group.

      Owners can add and remove users and edit the group's properties.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/ownerships', 'Lists the groups that the current user owns.'
  description <<-EOS
    Lists the groups that the current user owns.

    #{json_schema(Api::V1::GroupOwnersRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, GroupOwner)
    respond_with current_human_user.group_owners, location: nil
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:group_id/owners/:user_id',
             'Makes the given user an owner of the given Group.'
  description <<-EOS
    Makes the given user an owner of the given group.

    The current user must be a current owner of the group.
  EOS
  def create
    go = GroupOwner.new
    go.group_id = params[:group_id]
    go.user_id = params[:user_id]
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, go)

    if go.save
      respond_with go, status: :created, location: nil
    else
      render json: go.errors, status: :unprocessable_entity
    end
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/groups/:group_id/owners/:user_id',
               'Deletes a GroupOwner, removing the user from the Group\'s list of owners.'
  description <<-EOS
    Deletes a GroupOwner, removing the associated user from the Group\'s list of owners.

    The current user must be an owner of the group.
  EOS
  def destroy
    go = GroupOwner.where(group_id: params[:group_id],
                          user_id: params[:user_id]).first
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, go)

    if go.destroy
      head :no_content
    else
      render json: go.errors, status: :unprocessable_entity
    end
  end

end
