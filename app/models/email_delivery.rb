class EmailDelivery < ApplicationRecord
  SIGNUP_CONFIRMATION = 'signup_confirmation'.freeze

  # Positional integer enum -- append only.
  enum status: %i[queued send_error sent delayed delivered bounced complained rejected]

  # SES events arrive out of order, so a status only moves up this ranking
  RANK = {
    'queued' => 0,
    'send_error' => 1,
    'sent' => 2,
    'delayed' => 3,
    'delivered' => 4,
    'bounced' => 5,
    'rejected' => 5,
    'complained' => 6
  }.freeze

  PROBLEM_STATUSES = %w[send_error bounced complained rejected].freeze

  SECONDS_TO_DELIVER = 'EXTRACT(EPOCH FROM delivered_at - created_at)'.freeze

  belongs_to :contact_info

  scope :signup_confirmations, -> { where(kind: SIGNUP_CONFIRMATION) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def self.track_signup_confirmation!(email_address)
    create!(
      contact_info: email_address,
      kind: SIGNUP_CONFIRMATION,
      recipient: email_address.value,
      status: :queued,
      status_changed_at: Time.current
    )
  end

  def self.event_tracking_enabled?
    configuration_set.present?
  end

  def self.configuration_set
    Rails.application.secrets.dig(:aws, :ses, :configuration_set).presence
  end

  # Keeps environments sharing a topic from updating each other's rows
  def self.environment_tag
    Rails.application.secrets.environment_name.to_s.gsub(/[^A-Za-z0-9_-]/, '-')
  end

  def advance!(to, detail: nil, at: Time.current, **attributes)
    with_lock do
      next false if RANK.fetch(to.to_s) < RANK.fetch(status)

      update!(
        status: to,
        status_detail: detail&.to_s&.truncate(1000),
        status_changed_at: at,
        **attributes
      )
    end
  end

  def problem?
    PROBLEM_STATUSES.include?(status)
  end

  def seconds_to_deliver
    return if delivered_at.nil?

    (delivered_at - created_at).round
  end

  def self.signup_confirmation_stats(since: 7.days.ago)
    Rails.cache.fetch(['email_delivery_stats', since.to_date], expires_in: 10.minutes) do
      scope = signup_confirmations.where(created_at: since..)
      counts = scope.group(:status).count
      total = counts.values.sum

      delivered = scope.delivered
      timings = delivered.pick(
        Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{SECONDS_TO_DELIVER})"),
        Arel.sql("percentile_cont(0.9) WITHIN GROUP (ORDER BY #{SECONDS_TO_DELIVER})")
      ) || []

      {
        since: since,
        total: total,
        counts: counts,
        delivered_percent: percent(counts['delivered'], total),
        problem_percent: percent(PROBLEM_STATUSES.sum { |s| counts[s].to_i }, total),
        median_seconds_to_deliver: timings[0]&.round,
        p90_seconds_to_deliver: timings[1]&.round
      }
    end
  end

  def self.percent(count, total)
    return if total.zero?

    (100.0 * count.to_i / total).round(1)
  end
  private_class_method :percent
end
