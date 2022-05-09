bundle_command = ENV.fetch('BUNDLE_COMMAND', nil) || 'bundle exec'

set :bundle_command, bundle_command
set :runner_command, "#{bundle_command} rails runner"

# Server time is UTC; times below are interpreted that way.
# Ideally we'd have a better way to specify times relative to Central
# time, independent of the server time.  Maybe there's something here:
#   * https://github.com/javan/whenever/issues/481
#   * https://github.com/javan/whenever/pull/239

every(1.minute) { rake 'cron:minute' }

every('5,35 * * * *') { rake 'cron:5-past-half-hour' }

every('20,50 * * * *') { rake 'cron:10-to-half-hour' }

every(1.day, at: Time.parse('2:30 AM CST').utc) { rake 'cron:day' }
