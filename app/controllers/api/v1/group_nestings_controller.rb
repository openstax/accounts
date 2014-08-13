class Api::V1::GroupNestingsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a Group nesting.'
    description <<-EOS
      GroupNestings represent nested Groups.
    EOS
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:container_group_id/nestings/:member_group_id',
             'Adds a given member Group as a nested group under the given container Group.'
  description <<-EOS
    Adds a given member Group as a nested group under the given container Group.

    The current user must be an owner of both Groups.
  EOS
  def create
    gn = GroupNesting.new
    gn.container_group_id = params[:group_id]
    gn.member_group_id = params[:id]
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, gn)

    if gn.save
      respond_with gn, status: :created
    else
      render json: gn.errors, status: :unprocessable_entity
    end
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/groups/:container_group_id/nestings/:member_group_id',
               'Deletes a GroupNesting, removing the member Group from the container Group.'
  description <<-EOS
    Deletes a GroupNesting, removing the member Group from the container Group.

    The current user must be an owner of either group.
  EOS
  def destroy
    gn = GroupNesting.where(container_group_id: params[:group_id],
                            member_group_id: params[:id]).first
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, gn)

    if gn.destroy
      head :no_content
    else
      render json: gn.errors, status: :unprocessable_entity
    end
  end

end
