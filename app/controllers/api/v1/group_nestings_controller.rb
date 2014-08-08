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

  api :POST, '/groups/:container_group_id/group_nestings', 'Adds a given member Group as a nested group under the given container Group.'
  description <<-EOS
    Adds a given member Group as a nested group under the given container Group.

    The current user must be an owner of both Groups.

    #{json_schema(Api::V1::GroupNestingRepresenter, include: :writeable)}
  EOS
  def create
    standard_create(GroupNesting) do |gn|
      gn.container_group_id = params[:group_id]
    end
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_nestings/:id', 'Deletes a GroupNesting, removing the member Group from the container Group.'
  description <<-EOS
    Deletes a GroupNesting, removing the member Group from the container Group.

    The current user must be an owner of either group.
  EOS
  def destroy
    standard_destroy(GroupNesting, params[:id])
  end

end
