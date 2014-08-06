class Api::V1::GroupNestingsController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'A representation of a group nesting.'
    description <<-EOS
      GroupNestings represent groups as members of other groups.
    EOS
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/groups/:container_group_id/group_nestings', 'Adds a nested group to the given container group.'
  description <<-EOS
    Adds a nested group to the given container group.

    The current user must either be an owner or manager of the container group and must be a staff (any role) of the member group.

    #{json_schema(Api::V1::GroupNestingRepresenter, include: :writeable)}
  EOS
  def create
    standard_create(GroupNesting) do |group_nesting|
      group_group.container_group_id = params[:group_id]
    end
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/group_nestings/:id', 'Deletes a GroupNesting, removing the member group from the container group.'
  description <<-EOS
    Deletes a GroupNesting, removing the member group from the container group.

    The current user must either be an owner or manager of the container group.
  EOS
  def destroy
    standard_destroy(GroupNesting, params[:id])
  end

end
