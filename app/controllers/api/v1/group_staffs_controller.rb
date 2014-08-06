class Api::V1::GroupStaffsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group staff.'
    description <<-EOS
      GroupStaffs represent staff of a Group.

      The role indicates what the user is allowed to do with the group.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/group_staffs', 'Lists the groups for which the current user is a staff.'
  description <<-EOS
    Shows the groups for which the current user is a staff, with added role information.

    #{json_schema(Api::V1::GroupStaffsRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, GroupStaff)
    respond_with current_human_user.group_staffs
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:group_id/group_staffs', 'Adds a given user to the given Group as staff.'
  description <<-EOS
    Adds a given user to the given Group as staff.

    The current user must be an owner of the group.

    #{json_schema(Api::V1::GroupStaffRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupStaff, :group, params[:group_id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_staffs/:id', 'Deletes a GroupStaff, removing the associated user from the Group\'s staff.'
  description <<-EOS
    Deletes a GroupStaff, removing the associated user from the Group\'s staff.

    The current user must be an owner of the group.
  EOS
  def destroy
    standard_destroy(GroupStaff, params[:id])
  end

end
