class Api::V1::GroupsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A group of users of OpenStax.'
    description <<-EOS
      Groups have a name and a collection of users.

      Managers are allowed to add and remove unprivileged users from the group.

      Owners can manage all users and their permissions,
      as well as rename the group.

      Applications acting on behalf of users have the same permissions
      as the user they are acting for.

      Applications acting for themselves can read any group with a member that
      uses that app.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/groups', 'Lists the Groups the current user is a member of.'
  description <<-EOS
    Shows a list of Groups the current user is a member of.

    #{json_schema(Api::V1::GroupsRepresenter, include: :readable)}
  EOS
  def index
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/groups/:id', 'Gets the specified Group.'
  description <<-EOS
    Shows the specified Group.

    At least one of the Group members must have given
    the current application read permissions.

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

    #{json_schema(Api::V1::GroupRepresenter, include: [:writeable])}
  EOS
  def create
    standard_nested_create(Group, :user, current_human_user.id)
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/groups/:id', 'Updates the properties of a Group.'
  description <<-EOS
    Updates the properties of a Group.

    Currently this can only be used to rename the Group.
  EOS
  def update
    standard_update(Group, params[:id])
  end

end
