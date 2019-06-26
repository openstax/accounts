desc "Find possible duplicate acccounts"
task find_duplicate_accounts: [:environment] do
  CSV.open("duplicate_users_by_name.csv", 'w+') do |csv|
    csv << ['User First Name',
            'User Last Name',
            'Username',
            'Created At',
            'Email Address(es)',
            'User ID',
            'Applications',
            'Authentications',
            'Signup Successful?',
            'Reset Password Help Requested?',
            'Help Request Failed?',
            'Authentication Transfer Failed?'
          ]

    # self-join using baby_squeel :)
    same = BabySqueel[:same]
    where_names_match = User.joining{
      on {
        (id != same.id) & (first_name.lower == same.first_name.lower) & (last_name.lower == same.last_name.lower)
      }.as('same')
    }.uniq.preload(:security_logs, :applications, :authentications, :contact_infos)

    where_names_match.find_each do |user|
      csv << [user.first_name,
              user.last_name,
              user.username,
              user.created_at.to_s,
              (user.contact_infos.any? ? user.contact_infos.map{ |ci| "#{ci.value} #{ci.verified ? '(verified)' : '(NOT verified)'}" }.join(", ") : ""),
              user.id,
              (user.applications.any? ? ( user.applications.map(&:name).join(", ") ) : ""),
              (user.authentications.any? ? user.authentications.map(&:display_name).join(", ") : ""),
              sign_up_successful(user),
              help_requested(user),
              help_request_failed(user),
              authentication_transfer_failed(user)
             ]
    end
  end

  CSV.open("duplicate_users_by_email.csv", 'w+') do |csv|
    csv << ['Email Address',
            'Created At',
            'ContactInfo ID',
            'User First Name',
            'User Last Name',
            'Username',
            'User ID',
            'Applications',
            'Authentications',
            'Signup Successful?',
            'Reset Password Help Requested?',
            'Help Request Failed?',
            'Authentication Transfer Failed?'
           ]

    # self-join using baby_squeel :)
    same = BabySqueel[:same]
    where_email_addresses_match = ContactInfo.joining{
        on{ (id != same.id) & (value.lower == same.value.lower) }.as('same')
      }.joining{ user.outer }.preload(user: [:security_logs, :applications, :authentications]).uniq

    where_email_addresses_match.find_each do |contact_info|
      user = contact_info.user
      csv << [
              "#{contact_info.value} #{contact_info.verified ? '(verified)' : '(NOT verified)'}",
              contact_info.created_at.to_s,
              contact_info.id,
              user.try(:first_name),
              user.try(:last_name),
              user.try(:username),
              user.try(:id),
              (user && user.applications.any?)    ? user.applications.map(&:name).join(", ") : "",
              (user && user.authentications.any?) ? user.authentications.map(&:display_name).join(", ") : "",
              sign_up_successful(user),
              help_requested(user),
              help_request_failed(user),
              authentication_transfer_failed(user)
             ]
    end
  end
end

private

def sign_up_successful(user)
  return if user.nil?
  user.security_logs.where(event_type: SecurityLog.event_types[:sign_up_successful]).map{|sec| "On #{sec.created_at}"}.join(" and ")
end

def help_requested(user)
  return if user.nil?
  user.security_logs.where(event_type: SecurityLog.event_types[:help_requested]).map{|sec| "On #{sec.created_at}"}.join(" and ")
end

def help_request_failed(user)
  return if user.nil?
  user.security_logs.where(event_type: SecurityLog.event_types[:help_request_failed]).map{|sec| "On #{sec.created_at}"}.join(" and ")
end

def authentication_transfer_failed(user)
  return if user.nil?
  user.security_logs.where(event_type: SecurityLog.event_types[:authentication_transfer_failed]).map{|sec| "On #{sec.created_at}"}.join(" and ")
end
