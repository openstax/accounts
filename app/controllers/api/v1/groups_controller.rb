class Api::V1::GroupsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A group of users of OpenStax.'
    description <<-EOS
      Groups have an owner, a name, a visibility setting (is_public)
      and a collection of users.

      Owners can manage group members, rename and delete the group.

      Managers can manage group members.

      Members and Viewers can view private groups.
      Members are also listed as being in the group.

      Although groups are created by users through applications, they do not
      belong to any specific application. As such, applications acting on behalf of
      users have the same permissions as the user they are acting for.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/groups', 'Lists the visible Groups for the current user.'
  description <<-EOS
    Shows the list of visible Groups for the current user.
    These groups can be reused by this user in any OpenStax application.

    #{json_schema(Api::V1::GroupsRepresenter, include: :readable)}
  EOS
  def index
    respond_with Group.visible_for(current_human_user)
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/groups/:id', 'Gets the specified Group.'
  description <<-EOS
    Shows the specified Group, including name and list of members.

    Required permission depends on the group's is_public setting.

    #{json_schema(Api::V1::GroupRepresenter, include: :readable)}
  EOS
  def show
    standard_read(Group, params[:id])
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups', 'Creates a new Group.'
  description <<-EOS
    Creates a new Group and sets the current user as an owner.

    #{json_schema(Api::V1::GroupRepresenter, include: :writeable)}
  EOS
  def create
    standard_create(Group) do |group|
      group.add_user(current_human_user, :owner)
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/groups/:id', 'Updates the properties of a Group.'
  description <<-EOS
    Updates the properties of a Group.

    Requires the current user to be an owner of the group.

    #{json_schema(Api::V1::GroupRepresenter, include: :writeable)}
  EOS
  def update
    standard_update(Group, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/groups/:id', 'Deletes the specified group.'
  description <<-EOS
    Deletes a Group.

    Requires the current user to be an owner of the group.
  EOS
  def destroy
    standard_destroy(Group, params[:id])
  end

end
