class ChangeApplicationOwnersToGroups < ActiveRecord::Migration[4.2]
  def up
    Doorkeeper::Application.all.each do |app|
      user = app.owner
      next if user.is_a? Group
      g = Group.new
      g.name = "#{app.name} Owners"
      g.add_member(user)
      g.add_owner(user)
      g.save!
      app.owner = g
      app.save!
    end
  end

  def down
    Doorkeeper::Application.all.each do |app|
      group = app.owner
      next if group.is_a? User
      app.owner = group.group_owners.first.user
      app.save!
      group.destroy
    end
  end
end
