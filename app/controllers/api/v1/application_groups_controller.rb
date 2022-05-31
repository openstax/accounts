class Api::V1::ApplicationGroupsController < Api::V1::ApiController
  resource_description do
    api_versions "v1"
    short_description 'Records which applications interact with which groups.'
    description <<-EOS
      All actions in this controller operate only on ApplicationGroups that
      belong to the current application, as determined from the Oauth token.

      ApplicationGroups are automatically created for all existing ApplicationUsers
       for an app when it requests ApplicationGroup updates.
      They record which groups have updates available for which OpenStax Accounts applications.
    EOS
  end

  ###############################################################
  # updates
  ###############################################################

  api :GET, '/application_groups/updates',
            'Gets all ApplicationGroups with unread updates for the current app.'
  description <<-EOS
    Can only be called by an application through the client credentials flow.
    Returns all ApplicationGroups for the current application that have unread updates.
    Useful for caching Group information.

    #{json_schema(Api::V1::ApplicationGroupsRepresenter, include: :readable)}
  EOS
  def updates
    OSU::AccessPolicy.require_action_allowed!(:updates, current_api_user, ApplicationGroup)
    outputs = GetUpdatedApplicationGroups.call(current_application).outputs
    respond_with outputs[:application_groups], represent_with: Api::V1::ApplicationGroupsRepresenter, location: nil
  end

  ###############################################################
  # updated
  ###############################################################

  api :PUT, '/application_groups/updated', 'Marks ApplicationGroup updates as "read"'
  description <<-EOS
    Can only be called by an application through the client credentials flow.
    Marks ApplicationGroup updates as read for the current application.
    Useful for caching Group information.

    * `application_groups` &ndash; Array containing info about the ApplicationGroups whose updates were read. The 'id' and 'read_updates' fields are mandatory. "read_updates" should contain the last value for "unread_updates" received by the app.

    Examples:

    Assume your app called `updates` and got an ApplicationUser with id: 42 and unread_updates: 2

    `application_groups = {id: 42, read_updates: 2}` &ndash; this is the correct call to `updated`, and marks the ApplicationUser updates as `read` by setting unread_updates to 0.

    Assume your app called `updates` and got an ApplicationGroup with id: 13 and unread_updates: 1

    After you called the API and received your response, the group had a member added, setting unread_updates to 2.

    `application_groups = {id: 13, read_updates: 1}` &ndash; will not affect the record. The group will be sent again the next time you call `updates`, so you won't miss the updated information.
  EOS
  def updated
    OSU::AccessPolicy.require_action_allowed!(:updated, current_api_user, ApplicationGroup)
    errors = MarkApplicationGroupUpdatesAsRead.call(current_application,
               ActiveSupport::JSON.decode(request.body.string)).errors
    head(errors.any? ? :internal_server_error : :no_content)
  end

end
