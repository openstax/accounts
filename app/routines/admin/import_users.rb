module Admin
  class ImportUsers
    lev_routine

    protected

    def exec(filename: 'users.json')
      num_users = 0
      errors = []
      JSON.parse(File.read(filename)).each do |user_hash|
        user = User.new(user_hash.except('id', 'identity', 'authentications', 'contact_infos'))

        identity_hash = user_hash['identity']
        user.identity = Identity.new(identity_hash) unless identity_hash.nil?

        user.authentications.concat user_hash['authentications'].map do |authentication_hash|
          Authentication.new(authentication_hash)
        end

        user.contact_infos.concat user_hash['contact_infos'].map do |contact_info_hash|
          ContactInfo.new(contact_info_hash)
        end

        errors.concat(user.errors) unless user.save
      end

      Rails.logger.info { "Imported #{num_users} user(s) with #{errors.size} error(s)." }
      Rails.logger.info { "Errors: #{errors.inspect}" } unless errors.empty?
    end
  end
end
