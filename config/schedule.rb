bundle_command = ENV['BUNDLE_COMMAND'] || 'bundle exec'

set :bundle_command, bundle_command
set :runner_command, "#{bundle_command} rails runner"

# Server time is UTC; times below are interpreted that way.
# Ideally we'd have a better way to specify times relative to Central
# time, independent of the server time.  Maybe there's something here:
#   * https://github.com/javan/whenever/issues/481
#   * https://github.com/javan/whenever/pull/239

every '5,35 * * * *' do
  runner <<-CMD
    OpenStax::RescueFrom.this{
      UpdateUserSalesforceInfo.call(allow_error_email: Time.zone.now.hour == 0 && Time.zone.now.min < 10)
    }
  CMD
end

every 1.day, at: Time.parse('2:30 AM CST').utc do
  rake 'doorkeeper:cleanup'
end
