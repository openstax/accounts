# Access Policies

As this application grows to include different kinds of users, including signed-in and anonymous human users as well as other applications, the logic for controlling which user has which accesses to which resources can grow complex.  Controllers certainly aren't the place for this logic.  In a case with one kind of User, models *may* be the place for this logic but even then this makes models know way too much about other models.  

Access Policies were created to be a dedicated place to store the logic controlling who has access to what.  All other code can ask the `AccessPolicy` class for this info, via the `action_allowed?` or the convenience methods `read_allowed?`, `create_allowed?`, `update_allowed?`, `delete_allowed?`, and `sort_allowed?`.  `AccessPolicy` then delegates the access decisions off to other policy classes, of which there is normally one per kind of resource (e.g. a `UserAccessPolicy`, `ContactInfoPolicy`, etc).  

These resource-specific policy classes register themselves with the main `AccessPolicy` class, telling `AccessPolicy` what kinds of resources they can handle.  E.g. the `UserAccessPolicy` tells `AccessPolicy` it handles permissions for `User` with the following call:

    AccessPolicy.register(User, UserAccessPolicy)

This call is typically made after the policy class' definition so that it is called when the Rails application is loaded.  All files in the `access_policies` directory are autoloaded by Rails.
