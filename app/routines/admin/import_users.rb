module Admin
  class ImportUsers
    lev_routine

    protected

    def exec(filename: 'users.json')
      num_users = 0
      outputs.failures = []
      JSON.parse(File.read(filename)).each do |user_hash|
        user = mass_assign(
          User, user_hash.except('id', 'identity', 'authentications', 'contact_infos')
        )

        user_hash['contact_infos'].each do |contact_info_hash|
          user.contact_infos << mass_assign(ContactInfo, contact_info_hash)
        end

        identity_hash = user_hash['identity']
        unless identity_hash.nil?
          user.identity = mass_assign(Identity, identity_hash) unless identity_hash.nil?

          # validate: false is necessary because we don't validate the identity without the password
          # saving here is necessary so the authentications can use the identity's id
          user.identity.save validate: false
        end

        user_hash['authentications'].each do |authentication_hash|
          authentication = mass_assign(Authentication, authentication_hash)
          authentication.uid = user.identity.id.to_s if authentication.provider == 'identity'
          user.authentications << authentication
        end

        outputs.failures << user unless user.save
      end

      Rails.logger.info { "Imported #{num_users} user(s) with #{outputs.failures.size} error(s)." }
      Rails.logger.info { "Errors: #{outputs.failures.map(&:errors).inspect}" } \
        unless outputs.failures.empty?
    end

    # Necessary because the calls to attr_accessible block all mass-assignment
    # Remove when we get rid of attr_accessible
    def mass_assign(klass, attribute_hash)
      klass.new.tap do |instance|
        attribute_hash.each { |attribute, value| instance.public_send("#{attribute}=", value) }
      end
    end
  end
end
