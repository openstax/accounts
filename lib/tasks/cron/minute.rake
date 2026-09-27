namespace :cron do
  task minute: :log_to_stdout do
    Rails.logger.debug 'Starting minute cron'

    cron_step('rake aws:update_cloudwatch_metrics') do
      Rake::Task['aws:update_cloudwatch_metrics'].invoke
    end

    cron_step('rake delayed:heartbeat:delete_timed_out_workers') do
      Rake::Task['delayed:heartbeat:delete_timed_out_workers'].invoke
    end

    Rails.logger.debug 'Finished minute cron'
  end
end
