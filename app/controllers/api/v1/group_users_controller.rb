class Api::V1::GroupUsersController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group member.'
    description <<-EOS
      GroupUsers represent members of a Group.

      Group owners and anyone with whom the group is shared with edit permission
      can add and remove members.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/group_users', 'Lists the Group memberships for the current user.'
  description <<-EOS
    Shows the list of GroupUsers for the current user, that is,
    the list of Groups that the current user is a member of.

    #{json_schema(Api::V1::GroupUsersRepresenter, include: :readable)}
  EOS
  def index
    respond_with GroupUser.where(:user_id => current_human_user.id)
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:id/group_users', 'Adds a given user to the given Group.'
  description <<-EOS
    Adds a given user to the given Group.

    The current user must own the group or have it shared with them with edit permission.

    #{json_schema(Api::V1::GroupUserRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupUser, :group, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_users/:id', 'Deletes a GroupUser, removing its associated user from the Group.'
  description <<-EOS
    Deletes a GroupUser, removing its associated user from the Group.

    The current user must either own the group, have the group shared with them
    with edit permission, or be the user the group_user refers to.
  EOS
  def destroy
    standard_destroy(GroupUser, params[:id])
  end

end
