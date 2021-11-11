# http://jerryclinesmith.me/blog/2014/01/16/logging-from-rake-tasks/
desc "Include this task as another task's dependency to cause Rails.logger to also print to STDOUT"
task :log_to_stdout, [ :log_level ] => :environment do |tt, args|
  # Do nothing in the test environment, since we don't want stdout there
  next if Rails.env.test?

  # Clone the main Rails logger to dissociate it from the other module loggers
  # so we don't receive database, background job and mailer logs
  Rails.logger = Rails.logger.clone

  stdout_logger = ActiveSupport::Logger.new(STDOUT)

  # By default, use a log level of at least 1 so we don't receive debug messages
  stdout_logger.level = args.fetch(:log_level) do
    ENV.fetch('LOG_LEVEL') { [ Rails.logger.level, 1 ].max }
  end
  stdout_logger.formatter = Rails.logger.formatter

  Rails.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
end
