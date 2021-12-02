namespace :cron do
  task day: :log_to_stdout do
    Rails.logger.debug 'Starting daily cron'

    Rails.logger.info 'rake doorkeeper:cleanup'
    OpenStax::RescueFrom.this { Rake::Task['doorkeeper:cleanup'].invoke }

    Rails.logger.debug 'Finished daily cron'
  end
end
