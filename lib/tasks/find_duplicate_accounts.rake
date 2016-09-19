desc "Find possible duplicate acccounts"
task :find_duplicate_accounts => [:environment] do
  CSV.open("duplicate_users_by_name.csv", 'w+') do |csv|
    csv << ['User First Name',
            'User Last Name',
            'Created At',
            'Email Address(es)',
            'User ID',
            'Applications',
            'Signup Successful?',
            'Reset Password Help Requested?',
            'Help Request Failed?',
            'Authentication Transfer Failed?'
          ]

    where_names_match = User.joins{ User.unscoped.as(same)
                    .on{
                      (same.id != ~id) & (lower(same.first_name) == lower(~first_name)) & (lower(same.last_name) == lower(~last_name))
                    }
                  }.uniq.order(:first_name, :last_name).includes(:security_logs)

    where_names_match.find_each do |user|
      csv << [user.first_name,
              user.last_name,
              user.created_at.to_s,
              (user.contact_infos.any? ? user.contact_infos.map{ |ci| "#{ci.value} #{ci.verified ? '(verified)' : '(NOT verified)'}" }.join(", ") : ""),
              user.id,
              (user.applications.any? ? ( user.applications.map(&:name).join(", ") ) : ""),
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
            'User ID',
            'Applications',
            'Signup Successful?',
            'Reset Password Help Requested?',
            'Help Request Failed?',
            'Authentication Transfer Failed?'
           ]

    where_email_addresses_match = ContactInfo.joins{ ContactInfo.unscoped.as(same)
                                               .on{ (same.id != ~id) & (lower(same.value) == lower(value)) }
                                    }.joins{ user.outer }.preload(:user).uniq

    where_email_addresses_match.find_each do |contact_info|
      csv << [
              "#{contact_info.value} #{contact_info.verified ? '(verified)' : '(NOT verified)'}",
              contact_info.created_at.to_s,
              contact_info.id,
              contact_info.user.try(:first_name),
              contact_info.user.try(:last_name),
              contact_info.user.try(:id),
              (contact_info.user && contact_info.user.applications.any?) ? contact_info.user.applications.map(&:name).join(", ") : "",
              sign_up_successful(contact_info.user),
              help_requested(contact_info.user),
              help_request_failed(contact_info.user),
              authentication_transfer_failed(contact_info.user)
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
