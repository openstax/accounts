class ChangeApplicationOwnersToGroups < ActiveRecord::Migration
  def up
    Doorkeeper::Application.all.each do |app|
      user = app.owner
      next if user.is_a? Group
      g = Group.new
      g.name = "#{app.name} Owners"
      g.owner = g
      g.add_user(user)
      g.save!
      app.owner = g
      app.save!
    end
  end

  def down
    Doorkeeper::Application.all.each do |app|
      group = app.owner
      next if group.is_a? User
      app.owner = group.group_users.owners.first.user
      app.save!
      group.destroy
    end
  end
end
