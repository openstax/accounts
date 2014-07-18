class Api::V1::GroupGroupsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group delegating permissions to another group.'
    description <<-EOS
      GroupGroups represent groups delegating permissions to another group.

      The role indicates what the permitted group is allowed to do with the permitter group.

      Groups cannot be nested, therefore the member role is unavailable in GroupGroups
    EOS
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:id/group_groups', 'Adds a permitted group to the given permitter group.'
  description <<-EOS
    Adds a permitted group to the given permitter group with staff permissions.

    The current user must either be an owner or manager of the group.

    The role can be specified, but managers cannot add owners or other managers.

    Groups cannot be nested, so the member role is unavailable.

    #{json_schema(Api::V1::GroupGroupRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupGroup, :group, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_groups/:id', 'Deletes a GroupGroup, removing the permitted group\'s permissions from the permitter group.'
  description <<-EOS
    Deletes a GroupGroup, removing the permitted group's permissions from the permitter group.

    The current user must either be an owner or manager of the group.

    Managers cannot remove owners or other managers.
  EOS
  def destroy
    standard_destroy(GroupGroup, params[:id])
  end

end
