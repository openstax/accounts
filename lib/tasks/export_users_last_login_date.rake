desc "Creates a CSV file with users' last login date and their email addresses"
task :export_users_last_login_date => [:environment] do
  puts ExportUsersLastLoginDate.call(delete_after: false).outputs.filename
end
