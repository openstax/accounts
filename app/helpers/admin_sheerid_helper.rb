# Presentation for the SheerID panel on the admin user form.
module AdminSheeridHelper
  SHEERID_STEP_LABELS = {
    SheeridVerification::VERIFIED => %w[Verified success],
    SheeridVerification::REJECTED => %w[Rejected danger],
    SheeridVerification::PENDING => ['Pending document review', 'warning'],
    SheeridVerification::ERROR => %w[Error danger],
    'collectTeacherPersonalInfo' => ['Collecting info', 'info']
  }.freeze

  # Everything the webhook and the faculty-status ladder log about a user, not
  # just the event types that happen to start with "sheerid_".
  def sheerid_activity_event_types
    SecurityLog.event_types.keys.select do |type|
      type.include?('sheerid') || type.start_with?('fv_', 'faculty_')
    end
  end

  def sheerid_event_name(log)
    log.event_type.humanize.sub(/\bSheerid\b/i, 'SheerID')
  end

  def sheerid_step_badge(verification)
    text, style = SHEERID_STEP_LABELS.fetch(verification.current_step,
                                            [verification.current_step, 'default'])
    text = 'Expired' if verification.expired?
    content_tag(:span, text, class: "label label-#{style}")
  end

  def sheerid_timestamp(time)
    return content_tag(:span, 'never', class: 'text-muted') if time.nil?

    time.strftime('%b %-d, %Y, %-l:%M %p %Z')
  end

  def sheerid_list_or_none(values)
    return content_tag(:span, 'none', class: 'text-muted') if values.blank?

    Array(values).join(', ')
  end

  # One line per key, skipping the verification id (already shown in the panel
  # header) and blank values. A School hash collapses to its name.
  def sheerid_event_details(event_data)
    pairs = (event_data || {}).except('verification_id').reject { |_, v| v.blank? }
    return if pairs.empty?

    safe_join(pairs.map { |key, value|
      content_tag(:span, class: 'sheerid-verification__pair') do
        label = content_tag(:span, "#{key.to_s.humanize(capitalize: false)}: ", class: 'text-muted')
        safe_join([label, sheerid_event_value(value)])
      end
    }, ' ')
  end

  private

  def sheerid_event_value(value)
    case value
    when Hash then value['name'] || value[:name] || value.to_json.truncate(80)
    when Array then value.join(', ')
    else value.to_s
    end
  end
end
