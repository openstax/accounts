class Api::V1::GroupOwnersController < OpenStax::Api::V1::ApiController

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

  api :GET, '/group_owners', 'Lists the groups that the current user owns.'
  description <<-EOS
    Lists the groups that the current user owns.

    #{json_schema(Api::V1::GroupOwnersRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, GroupOwner)
    respond_with current_human_user.group_owners
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:group_id/group_owners', 'Makes the given user an owner of the given Group.'
  description <<-EOS
    Makes the given user an owner of the given group.

    The current user must be a current owner of the group.

    #{json_schema(Api::V1::GroupOwnerRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupOwner, :group, params[:group_id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_owners/:id', 'Deletes a GroupOwner, removing the user from the Group\'s list of owners.'
  description <<-EOS
    Deletes a GroupOwner, removing the associated user from the Group\'s list of owners.

    The current user must be an owner of the group.
  EOS
  def destroy
    standard_destroy(GroupOwner, params[:id])
  end

end
