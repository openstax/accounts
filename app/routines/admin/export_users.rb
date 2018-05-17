module Admin
  class ExportUsers
    lev_routine

    protected

    def exec(users:, filename: 'users.json')
      hash = users.map do |user|
        user.attributes.except('id').merge(
          'identity' => user.identity.try!(:attributes).try!(:except, 'id', 'user_id'),
          'authentications' => user.authentications.map do |authentication|
            authentication.attributes.except('id', 'user_id')
          end,
          'contact_infos' => user.contact_infos.map do |contact_info|
            contact_info.attributes.except('id', 'user_id')
          end
        )
      end

      File.write filename, hash.to_json
    end
  end
end
