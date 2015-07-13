# Creates a number of users themed from Hanna-Barbera cartoon characters.

PASSWORD = 'password'
filepath = File.join(Rails.root, 'db', 'seeds', 'hanna_barbera.yml')


yaml_root = YAML.load_file(filepath)
master_group = Group.find_or_create_by_name('hanna_barbera_group')

yaml_root['users'].each do |username, values|
  user_info = values.slice('first_name', 'last_name', 'full_name',
                           'title', 'suffix')
  # Create users...
  user = User.find_or_create_by_username(username)
  user.update_attributes(user_info)
  identity = Identity.find_or_create_by_user_id(user.id) do |identity|
    identity.password = PASSWORD
    identity.password_confirmation = PASSWORD
    identity.save!
  end
  user.is_administrator = values['is_administrator']
  user.state = 'activated'
  master_group.add_member(user)
  identity_uid = user.identity.id.to_s
  auth = Authentication.find_or_create_by_uid(identity_uid) do |auth|
    auth.provider = 'identity'
    auth.user_id = user.id
    auth.save!
  end
  user.save
end

yaml_root['groups'].each do |groupname, values|
  # Create groups
  group = Group.find_or_create_by_name(groupname)
  values['owners'].each do |username|
    user = User.find_by_username(username)
    group.add_owner(user)
  end
  values['members'].each do |username|
    user = User.find_by_username(username)
    group.add_member(user)
  end
end
