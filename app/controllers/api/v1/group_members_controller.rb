class Api::V1::GroupMembersController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group member.'
    description <<-EOS
      GroupMembers represent members of a Group.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/memberships', 'Lists the group memberships for the current user.'
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

  api :POST, '/groups/:group_id/members/:user_id',
             'Adds a given user as a member of the given Group.'
  description <<-EOS
    Adds a given user as a member of the given Group.

    The current user must be an owner of the group.
  EOS
  def create
    gm = GroupMember.new
    gm.group_id = params[:group_id]
    gm.user_id = params[:user_id]
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, gm)

    if gm.save
      respond_with gm, status: :created
    else
      render json: gm.errors, status: :unprocessable_entity
    end
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/groups/:group_id/members/:user_id',
               'Deletes a GroupMember, removing the associated user from the Group.'
  description <<-EOS
    Deletes a GroupMember, removing the associated user from the Group.

    The current user must be an owner of the group.
  EOS
  def destroy
    gm = GroupMember.where(group_id: params[:group_id],
                           user_id: params[:user_id]).first
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, gm)

    if gm.destroy
      head :no_content
    else
      render json: gm.errors, status: :unprocessable_entity
    end
  end

end
