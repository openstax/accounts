class ArchiveTempUsers
  def self.find_temp_users
    # make sure temp users only have "authentications" and "contact_infos", no
    # other associations
    temp_users = User.where(state: 'temp')
    exclude_user_ids = []

    app_users = temp_users.select(:id).joins(:application_users) \
                          .uniq.collect(&:id)
    $stderr.puts("These temp users are linked to an application: #{app_users.inspect}") \
      unless app_users.empty?
    exclude_user_ids += app_users

    group_owners = temp_users.select(:id).joins(:group_owners) \
                             .uniq.collect(&:id)
    $stderr.puts("These temp users are group owners: #{group_owners.inspect}") \
      unless group_owners.empty?
    exclude_user_ids += group_owners

    group_members = temp_users.select(:id).joins(:group_members) \
                              .uniq.collect(&:id)
    $stderr.puts("These temp users are group members: #{group_members.inspect}") \
      unless group_members.empty?
    exclude_user_ids += group_members

    temp_users = temp_users.where('id NOT IN (?)', exclude_user_ids) \
      unless exclude_user_ids.empty?

    temp_users.preload(:contact_infos, :authentications, :identity)
  end

  def self.run
    temp_users = find_temp_users
    timestamp = Time.now.utc.iso8601
    filename = "archived_temp_users.#{timestamp}.json"
    File.open(filename, 'w') do |f|
      f.write(JSON.pretty_generate(temp_users.collect { |u|
        u.attributes.merge(
          contact_infos: u.contact_infos.collect(&:attributes),
          authentications: u.authentications.collect(&:attributes),
          identity: u.identity.try(:attributes))
      }))
    end
    temp_users.each do |user|
      DestroyUser.call(user)
    end
    puts "Output in #{filename}"
  end
end
