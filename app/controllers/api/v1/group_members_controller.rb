class Api::V1::GroupMembersController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group member.'
    description <<-EOS
      GroupMembers represent members a Group.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/group_members', 'Lists the group memberships for the current user.'
  description <<-EOS
    Shows the group memberships for the current user.

    #{json_schema(Api::V1::GroupMembersRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, GroupMember)
    respond_with current_human_user.group_members
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:group_id/group_members', 'Adds a given user as a member of the given Group.'
  description <<-EOS
    Adds a given user as a member of the given Group.

    The current user must either be an owner or manager of the group.

    #{json_schema(Api::V1::GroupMemberRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupMember, :group, params[:group_id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_members/:id', 'Deletes a GroupMember, removing the associated user from the Group.'
  description <<-EOS
    Deletes a GroupMember, removing the associated user from the Group.

    The current user must either be an owner or manager of the group.
  EOS
  def destroy
    standard_destroy(GroupMember, params[:id])
  end

end
