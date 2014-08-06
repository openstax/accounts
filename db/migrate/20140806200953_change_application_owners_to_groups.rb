class ChangeApplicationOwnersToGroups < ActiveRecord::Migration
  def up
    Doorkeeper::Application.all.each do |app|
      user = app.owner
      next if user.is_a? Group
      g = Group.new
      g.name = "#{app.name} Owners"
      g.add_member(user)
      g.add_staff(user, :owner)
      g.save!
      app.owner = g
      app.save!
    end
  end

  def down
    Doorkeeper::Application.all.each do |app|
      group = app.owner
      next if group.is_a? User
      app.owner = group.group_staffs.owners.first.user
      app.save!
      group.destroy
    end
  end
end
