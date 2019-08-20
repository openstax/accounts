module Admin
  class ImportUsers
    lev_routine

    protected

    def exec(filename: 'users.json')
      outputs.users = []
      outputs.failures = []
      JSON.parse(File.read(filename)).each do |user_hash|
        user = User.new(user_hash.except('id', 'contact_infos', 'identity', 'authentications'))

        user_hash['contact_infos'].each do |contact_info_hash|
          user.contact_infos << ContactInfo.new(contact_info_hash)
        end

        identity_hash = user_hash['identity']
        unless identity_hash.nil?
          user.identity = Identity.new(identity_hash) unless identity_hash.nil?

          # validate: false is necessary because we don't validate the identity without the password
          # saving here is necessary so the authentications can use the identity's id
          user.identity.save validate: false
        end

        user_hash['authentications'].each do |authentication_hash|
          authentication = Authentication.new(authentication_hash)
          authentication.uid = user.identity.id.to_s if authentication.provider == 'identity'
          user.authentications << authentication
        end

        if user.save
          outputs.users << user
        else
          outputs.failures << user
        end
      end

      Rails.logger.info do
        "Imported #{outputs.users.size} user(s) with #{outputs.failures.size} error(s)."
      end
      Rails.logger.info do
        "Errors: #{outputs.failures.map(&:errors).inspect}"
      end unless outputs.failures.empty?
    end
  end
end
