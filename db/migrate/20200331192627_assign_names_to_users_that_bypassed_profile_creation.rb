class AssignNamesToUsersThatBypassedProfileCreation < ActiveRecord::Migration[5.2]
  def up
    User.joins(:application_users).where(state: :needs_profile).distinct.find_each do |user|
      next if user.username.present?

      email = user.email_addresses.verified.first
      username = if email.nil?
        SecureRandom.urlsafe_base64
      else
        email.value.split('@').first.gsub(/[^a-zA-Z\d]+/, '_')
      end

      user.update_attribute :username, username
    end
  end

  def down
  end
end
