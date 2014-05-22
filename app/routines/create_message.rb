# Creates a message from the given params
class CreateMessage

  lev_routine

protected

  def exec(app, to, subject, body, options = {})
    msg = Message.new

    msg.application = app
    msg.user = options[:user]
    msg.send_externally_now = options[:send_externally_now]

    msg.from = app.email_from_address

    parse_destinations(msg, app, to, options[:cc], options[:bcc])

    msg.subject = subject
    msg.subject_prefix = options[:subject_prefix] || \
                         app.email_subject_prefix

    body = Body.new
    body.html = options[:body][:html]
    body.text = options[:body][:text]
    body.short_text = options[:body][:short_text]
    msg.body = body

    msg.create!

    outputs[:message] = msg
  end

  def parse_destinations(msg, app, to, cc = [], bcc = [])
    # Build a map from array indices to user id's for to, cc and bcc fields
    user_id_map = {}
    destinations = to + cc + bcc
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
      ci_map[app_user.user_id] = app_user.default_contact_info.value

      # If no default contact info, just grab the first one (2 extra queries)
      ci_map[app_user.user_id] ||= app_user.user.contact_infos.first
    end

    # Assume we only deal with email addresses for now

    # Plug email addresses into the to, cc and bcc strings
    i = 0
    msg.to, msg.cc, msg.bcc = [to, cc, bcc].collect_with_index do |dest, d|
      dest.collect do |contact_info|
        user_id = user_id_map[i]
        i = i + 1
        # If this was a literal contact info, skip it
        next(contact_info) unless user_id

        # Otherwise, first add a new MessageRecipient to the message
        mr = MessageRecipient.new
        mr.recipient_id = user_id
        mr.recipient_type = 'User'
        mr.type = ['to', 'cc', 'bcc'][d]
        msg.recipients << mr

        # Then return the result from our maps
        ci_map[user_id_map[user_id]]
      end
    end
  end

end
