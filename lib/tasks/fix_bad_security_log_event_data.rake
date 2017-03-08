desc "Find possible duplicate acccounts"
task fix_bad_security_log_event_data: [:environment] do

  bad_to_fixed_event_data = {
    "---\n:reason: cannot_find_user\n" =>        "{\"reason\":\"cannot_find_user\"}",
    "---\n:reason: bad_password\n" =>            "{\"reason\":\"bad_password\"}",
    "---\n:reason: multiple_users\n" =>          "{\"reason\":\"multiple_users\"}",
    "---\n:reason: too_many_login_attempts\n" => "{\"reason\":\"too_many_login_attempts\"}"
  }

  bad_to_fixed_event_data.each do |bad, fix|
    ActiveRecord::Base.connection.execute(
      "update security_logs set event_data='#{fix}' where event_data='#{bad}'"
    )
  end
end
