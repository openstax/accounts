class Api::V1::GroupsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A group of users of OpenStax.'
    description <<-EOS
      Groups have a name and a collection of users.

      Managers are allowed to add and remove unprivileged users from the group.

      Owners can manage all users and their permissions,
      as well as rename the group.

      Although groups are created by users through applications, they do not
      belong to any specific application. As such:

      Applications acting on behalf of users have the same permissions
      as the user they are acting for.

      Applications acting for themselves can read any group with a member that
      uses that app.
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/groups/:id', 'Gets the specified Group.'
  description <<-EOS
    Shows the specified Group, including name and a list of members.

    Requires member access level.

    #{json_schema(Api::V1::GroupRepresenter, include: :readable)}
  EOS
  def show
    standard_read(Group, params[:id])
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/', 'Creates a new Group.'
  description <<-EOS
    Creates a new Group and sets the current user as the first
    member and owner.

    Grants the current user owner access level to the new group.

    #{json_schema(Api::V1::GroupRepresenter, include: :writeable)}
  EOS
  def create
    standard_create(Group) do |group|
      group.add_user(current_human_user, GroupUser::OWNER)
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/groups/:id', 'Updates the properties of a Group.'
  description <<-EOS
    Updates the properties of a Group.
    Currently can only be used to rename the group.

    Requires owner access level.

    #{json_schema(Api::V1::GroupRepresenter, include: :writeable)}
  EOS
  def update
    standard_update(Group, params[:id])
  end

end
