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
  # show
  ###############################################################

  api :GET, '/groups/:id/group_user', 'Shows the GroupUser for the current user and the given Group.'
  description <<-EOS
    Shows the GroupUser for the current user and the given Group.

    #{json_schema(Api::V1::GroupUserRepresenter, include: :readable)}
  EOS
  def show
    GroupUser.where(:user_id => current_human_user.id,
                    :group_id => params[:id]).first
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:id/group_users', 'Adds a given User to the given Group.'
  description <<-EOS
    Adds a given User to the given Group.

    The current user must be a Group manager or higher.

    #{json_schema(Api::V1::GroupUserRepresenter, include: [:writeable])}
  EOS
  def create
    standard_nested_create(GroupUser, :group, params[:id])
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/group_users/:id', 'Updates the access level of a GroupUser.'
  description <<-EOS
    Updates the access level of a GroupUser.

    Only group owners can use this API endpoint.
  EOS
  def update
    standard_update(GroupUser, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_users/:id', 'Deletes a GroupUser, removing its User from the Group.'
  description <<-EOS
    Deletes a GroupUser, removing its User from the Group.

    The current user must be a manager or higher to remove normal users.
    Only group owners can remove managers or higher.
  EOS
  def destroy
    standard_destroy(GroupUser, params[:id])
  end

end
