namespace :cron do
  task minute: :log_to_stdout do
    Rails.logger.debug 'Starting minute cron'

    Rails.logger.info 'rake aws:update_cloudwatch_metrics'
    OpenStax::RescueFrom.this { Rake::Task['aws:update_cloudwatch_metrics'].invoke }

    Rails.logger.info 'rake delayed:heartbeat:delete_timed_out_workers'
    OpenStax::RescueFrom.this { Rake::Task['delayed:heartbeat:delete_timed_out_workers'].invoke }

    Rails.logger.debug 'Finished minute cron'
  end
end
