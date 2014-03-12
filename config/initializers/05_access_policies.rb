AccessPolicy.register(User, UserAccessPolicy)
AccessPolicy.register(ContactInfo, ContactInfoAccessPolicy)
AccessPolicy.register(EmailAddress, ContactInfoAccessPolicy)
AccessPolicy.register(Doorkeeper::Application, Doorkeeper::ApplicationAccessPolicy)