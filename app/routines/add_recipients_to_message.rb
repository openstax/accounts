# Associates a Message with a list of recipients
class AddRecipientsToMessage

  lev_routine

  protected

  def exec(msg, type, dest)
    app = msg.application
    cis = [] # An array of ContactInfos

    # Ensure we have arrays
    literals, user_ids = [:literals, :user_ids].map do |s|
      next [] if dest[s].blank?
      next dest[s] if dest[s].is_a? Array
      dest[s].split(',').map(&:strip)
    end

    literal_cis = {} # A map from ContactInfo values to (existing) ContactInfos
    sort(ContactInfo.where(value: literals).preload(:user), :value, literals).each do |ci|
      literal_cis[ci.value] = ci
    end

    literals.each do |l|
      # Create a new ContactInfo if it doesn't exist
      # TODO: Parse type of literal (email, etc)
      cis << (literal_cis[l] || ContactInfo.create(type: 'EmailAddress', value: l))
    end

    user_cis = {} # A map from User ID's to (default) ContactInfos
    app.application_users.where(user_id: user_ids).preload(:default_contact_info).each do |app_user|
      user_cis[app_user.user_id] = app_user.default_contact_info
    end

    sort(User.where(id: user_ids).preload(:contact_infos), :id, user_ids).each do |user|
      # Grab the User's first ContactInfo if no default
      cis << (user_cis[user.id] || user.contact_infos.first)
    end

    cis.each do |ci|
      next if ci.blank?
      mr = MessageRecipient.new(message: msg, contact_info: ci,
                                user: ci.user, recipient_type: type.to_s)
      msg.message_recipients << mr
    end
  end

  def sort(array_like_object, field_symbol, ordered_values)
    # http://stackoverflow.com/a/15564039/1664216
    array_like_object.index_by(&field_symbol).slice(*ordered_values).values
  end

  def sorted_where(klass, key, values, includes)
    klass.where(key => values).preload(includes)
  end

end
