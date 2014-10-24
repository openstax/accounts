# Associates a Message with a list of recipients
class AddRecipientsToMessage

  lev_routine

  protected

  def exec(msg, type, dest)
    app = msg.application
    cis = [] # An array of ContactInfos

    # Ensure we have arrays
    literals, user_ids = [:literals, :user_ids].collect do |s|
      next [] if dest[s].blank?
      next dest[s] if dest[s].is_a? Array
      dest[s].split(',').collect{|d| d.strip}
    end

    literal_cis = {} # A map from ContactInfo values to (existing) ContactInfos
    ContactInfo.where(:value => literals).includes(:user).each do |ci|
      literal_cis[ci.value] = ci
    end

    literals.each do |l|
      # Create a new ContactInfo if it doesn't exist
      # TODO: Parse type of literal (email, etc)
      cis.push literal_cis[l] || ContactInfo.create(:type => 'EmailAddress', :value => l)
    end

    user_cis = {} # A map from User ID's to (default) ContactInfos
    app.application_users.where(:user_id => user_ids)
                         .includes(:default_contact_info).each do |app_user|
      user_cis[app_user.user_id] = app_user.default_contact_info
    end

    User.where(:id => user_ids).includes(:contact_infos).each do |user|
      # Grab the User's first ContactInfo if no default
      cis.push user_cis[user.id] || user.contact_infos.first
    end

    cis.each do |ci|
      next if ci.blank?
      mr = MessageRecipient.new(:message => msg, :contact_info => ci,
                                :user => ci.user, :recipient_type => type.to_s)
      msg.message_recipients.push mr
    end
  end

end
