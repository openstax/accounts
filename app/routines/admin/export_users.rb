module Admin
  class ExportUsers
    lev_routine

    protected

    def exec(users:, filename: 'users.json')
      hash = users.map do |user|
        user.attributes.except('id').merge(
          'identity' => user.identity&.attributes&.except('id', 'user_id'),
          'authentications' => user.authentications.map do |authentication|
            excluded_attributes = [ 'id', 'user_id' ]
            excluded_attributes << 'uid' if authentication.provider == 'identity'

            authentication.attributes.except(*excluded_attributes)
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
