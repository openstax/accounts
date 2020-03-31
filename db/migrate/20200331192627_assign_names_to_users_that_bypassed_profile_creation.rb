class AssignNamesToUsersThatBypassedProfileCreation < ActiveRecord::Migration[5.2]
  def up
    User.joins(:application_users).where(state: :needs_profile).distinct.find_each do |user|
      user.first_name ||= 'Unknown'
      user.last_name ||= user.email_addresses.verified.first&.value || 'Unknown'
      user.save!
    end
  end

  def down
  end
end
