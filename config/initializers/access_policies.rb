require_relative 'doorkeeper'

Rails.application.config.after_initialize do
  OSU::AccessPolicy.register(Doorkeeper::Application, Doorkeeper::ApplicationAccessPolicy)
  OSU::AccessPolicy.register(User, UserAccessPolicy)
  OSU::AccessPolicy.register(AnonymousUser, UserAccessPolicy)
  OSU::AccessPolicy.register(Identity, IdentityAccessPolicy)
  OSU::AccessPolicy.register(ContactInfo, ContactInfoAccessPolicy)
  OSU::AccessPolicy.register(EmailAddress, ContactInfoAccessPolicy)
  OSU::AccessPolicy.register(Authentication, AuthenticationAccessPolicy)
  OSU::AccessPolicy.register(ApplicationUser, ApplicationUserAccessPolicy)
  OSU::AccessPolicy.register(Message, MessageAccessPolicy)
  OSU::AccessPolicy.register(Group, GroupAccessPolicy)
  OSU::AccessPolicy.register(GroupMember, GroupMemberAccessPolicy)
  OSU::AccessPolicy.register(GroupOwner, GroupOwnerAccessPolicy)
  OSU::AccessPolicy.register(GroupNesting, GroupNestingAccessPolicy)
  OSU::AccessPolicy.register(ApplicationGroup, ApplicationGroupAccessPolicy)
  OSU::AccessPolicy.register(ExternalId, ExternalIdAccessPolicy)
end
