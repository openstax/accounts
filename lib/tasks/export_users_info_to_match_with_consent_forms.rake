desc "Creates a CSV file with basic user info to match up with info in consent forms"
task :export_users_info_to_match_with_consent_forms => [:environment] do
  puts ExportUsersInfoToMatchWithConsentForms.call(delete_after: false).outputs.filename
end
