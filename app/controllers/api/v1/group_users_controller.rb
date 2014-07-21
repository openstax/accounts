class Api::V1::GroupUsersController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group user.'
    description <<-EOS
      GroupUsers represent members or staff of a Group.

      The role indicates what the user is allowed to do with the group.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/group_users', 'Lists the group memberships for the current user.'
  description <<-EOS
    Shows the group memberships for the current user, with added role information.

    #{json_schema(Api::V1::GroupUsersRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, GroupUser)
    respond_with current_human_user.group_users
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:id/group_users', 'Adds a given user to the given Group.'
  description <<-EOS
    Adds a given user to the given Group either as a member or as staff.

    The current user must either be an owner or manager of the group.

    The role can be specified, but managers cannot add owners or other managers.

    #{json_schema(Api::V1::GroupUserRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupUser, :group, params[:group_id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_users/:id', 'Deletes a GroupUser, removing its associated user from the Group.'
  description <<-EOS
    Deletes a GroupUser, removing its associated user from the Group.

    The current user must either be an owner or manager of the group.

    Managers cannot remove owners or other managers.
  EOS
  def destroy
    standard_destroy(GroupUser, params[:id])
  end

end
