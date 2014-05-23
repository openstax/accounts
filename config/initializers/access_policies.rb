require 'doorkeeper/models/active_record/application'

OSU::AccessPolicy.register(User, UserAccessPolicy)
OSU::AccessPolicy.register(ContactInfo, ContactInfoAccessPolicy)
OSU::AccessPolicy.register(EmailAddress, ContactInfoAccessPolicy)
OSU::AccessPolicy.register(ApplicationUser, ApplicationUserAccessPolicy)
OSU::AccessPolicy.register(Doorkeeper::Application, Doorkeeper::ApplicationAccessPolicy)
