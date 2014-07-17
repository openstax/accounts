class Api::V1::GroupSharingsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group being shared.'
    description <<-EOS
      GroupSharings represent Groups being shared with Users or other Groups.

      Only group owners can share Groups.
    EOS
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:id/group_sharings', 'Shares the given group.'
  description <<-EOS
    Shares the given group with either a user or another group.

    The current user must own the group.

    #{json_schema(Api::V1::GroupSharingRepresenter, include: :writeable)}
  EOS
  def create
    standard_nested_create(GroupSharing, :group, params[:id])
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/group_sharings/:id', 'Updates the properties of a GroupSharing.'
  description <<-EOS
    Updates the properties of a GroupSharing.

    Requires the current user to be an owner of the associated group.

    #{json_schema(Api::V1::GroupSharingRepresenter, include: :writeable)}
  EOS
  def update
    standard_update(GroupSharing, params[:id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_sharings/:id', 'Deletes a GroupSharing.'
  description <<-EOS
    Deletes a GroupSharing, stopping the Group from being shared.

    The current user must either own the group, be the user the group_sharing refers to,
    or be a member of the group the group_sharing refers to.
  EOS
  def destroy
    standard_destroy(GroupSharing, params[:id])
  end

end
