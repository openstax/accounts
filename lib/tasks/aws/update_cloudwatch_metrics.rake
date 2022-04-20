namespace :aws do
  task update_cloudwatch_metrics: :environment do
    dj = Delayed::Job.arel_table
    current_time = Time.current
    max_run_time = Delayed::Worker.max_run_time
    environment_name = Rails.application.secrets.environment_name
    min_effective_run_at_by_queue = {}
    Delayed::Job.where(locked_at: nil).or(
      Delayed::Job.where(dj[:locked_at].lt current_time - max_run_time)
    ).where(dj[:run_at].lteq current_time).where(failed_at: nil).group(:queue).pluck(
      Arel.sql <<~SELECT
        "delayed_jobs"."queue", MIN(
          GREATEST(
            "delayed_jobs"."created_at",
            "delayed_jobs"."updated_at",
            "delayed_jobs"."run_at",
            "delayed_jobs"."locked_at" + INTERVAL '#{max_run_time} seconds'
          )
        ) AS "min_effective_run_at"
      SELECT
    ).each do |queue, min_effective_run_at|
      min_effective_run_at_by_queue[queue.sub("accounts_#{Rails.env}_", '')] = min_effective_run_at
    end

    require 'aws-sdk-cloudwatch'

    client = Aws::CloudWatch::Client.new
    default_dimensions = [
      { name: 'Application', value: 'Accounts' }, { name: 'Environment', value: environment_name }
    ]

    known_queues = Delayed::Worker.queue_attributes.keys.map(&:to_s)
    ([ nil ] + known_queues + [ 'other' ]).each_slice(20) do |queues|
      client.put_metric_data(
        namespace: 'DelayedJob',
        metric_data: queues.map do |queue|
          dimensions = default_dimensions
          dimensions += [ { name: 'Queue', value: queue } ] if queue.present?

          min_effective_run_at = if queue.blank?
            min_effective_run_at_by_queue.values.compact.min
          elsif queue == 'other'
            min_effective_run_at_by_queue.except(*known_queues).values.compact.min
          else
            min_effective_run_at_by_queue[queue]
          end

          {
            metric_name: 'MaxWait',
            dimensions: dimensions,
            timestamp: current_time,
            value: min_effective_run_at.nil? ? 0 : current_time - min_effective_run_at,
            unit: 'Seconds'
          }
        end
      )
    end
  end
end
