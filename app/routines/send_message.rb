# Sends a Message object
class SendMessage

  # This is already called from within the save transaction
  lev_routine transaction: :no_transaction

protected

  def exec(msg)
    to_string, cc_string, bcc_string = parse_destinations(msg)

    Mail.deliver do
      from msg.from
      to to_string
      cc cc_string
      bcc bcc_string
      subject msg.subject_string

      html_part do
        content_type 'text/html; charset=UTF-8'
        body msg.body.html
      end

      text_part do
        body msg.body.text
      end
    end
  end

  def parse_destinations(msg)
    app = msg.application

    # Convert strings to array
    to, cc, bcc = [msg.to, msg.cc, msg.bcc].collect do |dest|
      next [] if dest.blank?
      next dest if dest.is_a? Array
      dest.split(',').collect{|d| d.strip}
    end

    # Remove duplicates
    destinations = to
    cc -= destinations
    destinations += cc
    bcc -= destinations
    destinations += bcc

    # Build a map from array indices to user id's for to, cc and bcc fields
    user_id_map = {}
    destinations.each_with_index do |destination, i|
      # If not an integer, assume it's a literal contact info
      user_id_map[i] = Integer(destination) rescue next
    end

    # Perform only 1 or 2 queries
    app_users = app.application_users.where(
      :user_id => user_id_map.values).includes(:default_contact_info)

    # Build a map from user id's to contact info values
    ci_map = {}
    app_users.each do |app_user|
      ci_map[app_user.user_id] = app_user.default_contact_info.try(:value)

      # If no default contact info, just grab the first one (2 extra queries)
      ci_map[app_user.user_id] ||= app_user.user.contact_infos.first
    end

    # Assume we only deal with email addresses for now

    # Plug email addresses into the to, cc and bcc strings
    i = 0
    j = 0
    [to, cc, bcc].collect do |dest|
      d = dest.collect do |contact_info|
        user_id = user_id_map[j]
        j += 1
        # If this was a literal contact info, skip it
        next(contact_info) unless user_id

        # Otherwise, record who we are sending this message to
        mr = MessageRecipient.new
        mr.recipient_id = user_id
        mr.recipient_type = 'User'
        mr.type = ['to', 'cc', 'bcc'][i]
        msg.message_recipients << mr

        # Then return the result from our map
        ci_map[user_id].try(:value)
      end
      i += 1

      d.compact.join(', ')
    end
  end

end
