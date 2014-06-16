class Api::V1::GroupUsersController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group member.'
    description <<-EOS
      GroupUsers represent members of a Group.

      Group managers can add and remove members.

      Owners can add and remove anyone and promote members.
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

  api :POST, '/group_users', 'Adds a given user to the given Group.'
  description <<-EOS
    Adds a given user to the given Group.

    Requires manager access level.

    #{json_schema(Api::V1::GroupUserRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupUser, :group, params[:id])
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/group_users/:id', 'Updates the access level of a GroupUser.'
  description <<-EOS
    Updates the access level of a user associated with the given GroupUser.

    Requires owner access level.

    #{json_schema(Api::V1::GroupUserRepresenter, include: :writeable)}
  EOS
  def update
    standard_update(GroupUser, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_users/:id', 'Deletes a GroupUser, removing its associated user from the Group.'
  description <<-EOS
    Deletes a GroupUser, removing its associated user from the Group.

    Requires manager access level to remove normal users.
    Requires owner access level to remove managers or higher.
  EOS
  def destroy
    standard_destroy(GroupUser, params[:id])
  end

end
