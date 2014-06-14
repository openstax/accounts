class ChangeApplicationOwnersToGroups < ActiveRecord::Migration
  def up
    Doorkeeper::Application.each do |app|
      user = app.owner
      next if user.is_a? Group
      app.owner = Group.new
      app.owner.add_user(user)
      app.owner.save!
      app.save!
    end
  end

  def down
    Doorkeeper::Application.each do |app|
      group = app.owner
      next if user.is_a? User
      app.owner = group.group_users.owners.first.user
      app.save!
      group.destroy
    end
  end
end
