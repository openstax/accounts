require_relative 'doorkeeper'

OSU::AccessPolicy.register(Doorkeeper::Application, Doorkeeper::ApplicationAccessPolicy)
OSU::AccessPolicy.register(User, UserAccessPolicy)
OSU::AccessPolicy.register(AnonymousUser, UserAccessPolicy)
OSU::AccessPolicy.register(Identity, IdentityAccessPolicy)
OSU::AccessPolicy.register(ContactInfo, ContactInfoAccessPolicy)
OSU::AccessPolicy.register(EmailAddress, ContactInfoAccessPolicy)
OSU::AccessPolicy.register(Authentication, AuthenticationAccessPolicy)
OSU::AccessPolicy.register(ApplicationUser, ApplicationUserAccessPolicy)
