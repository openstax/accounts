module ImpactHelper
  def impact_currency_brief(value)
    return '—' if value.blank? || value.to_f <= 0

    amount = value.to_f

    if amount < 10_000
      rounded = ((amount / 100).round * 100)
      number_to_currency(rounded, precision: 0)
    else
      rounded = ((amount / 1_000).round * 1_000)
      units = { thousand: 'K', million: 'M', billion: 'B', trillion: 'T' }
      "$#{number_to_human(rounded,
                          units: units,
                          format: '%n%u',
                          precision: 0,
                          strip_insignificant_zeros: true)}"
    end
  end

  def impact_lead_sentence(has_adoptions:, stats:)
    unless has_adoptions
      return 'Once you report, your lifetime summary shows the students you reach and your estimated savings over time. Reports also help OpenStax secure the funding for new free titles.'
    end

    years = stats[:years].to_i
    period_text =
      if years <= 1
        safe_join(['the past ', content_tag(:strong, 'year')])
      else
        safe_join(['the past ', content_tag(:strong, years), ' ', content_tag(:strong, 'years')])
      end

    if stats[:savings].present? && stats[:savings] > 0
      formatted = impact_currency_brief(stats[:savings])
      safe_join([
        'Over ',
        period_text,
        ', your reported adoptions represent an estimated ',
        content_tag(:strong, formatted),
        ' in student savings.'
      ])
    else
      students = number_with_delimiter(stats[:students].to_i)
      safe_join([
        'Over ',
        period_text,
        ', your reported adoptions have supported ',
        content_tag(:strong, students),
        ' students.'
      ])
    end
  end

  def impact_milestone_text(stats)
    years = stats[:years].to_i
    students = stats[:students].to_i
    books = stats[:books].to_i

    if years >= 3
      'You’ve kept your adoption story current across multiple academic years. Thank you.'
    elsif students >= 300
      'You’ve supported hundreds of students through your reported adoptions.'
    elsif books >= 3
      'Your reported adoptions span multiple titles, and that visibility matters.'
    else
      'Every reported adoption shows how OpenStax books are used in real classrooms.'
    end
  end

  def impact_countup_value(value, format = 'integer')
    return impact_currency_brief(value) if format == 'currency'

    number_with_delimiter(value.to_i)
  end

  def milestone_progress_percent(current, target)
    return 0 if target.to_f.zero?

    [((current.to_f / target) * 100).round, 100].min
  end

  def impact_badge_subtext(timestamp)
    if timestamp.present?
      "Last reported #{timestamp.strftime('%b %-d, %Y')}"
    else
      'Report this year to get started'
    end
  end

  def impact_pending_badge(count, singular, plural = singular.pluralize)
    return if count.to_i <= 0

    noun = count == 1 ? singular : plural
    number = number_with_delimiter(count)

    content_tag(:span, class: 'impact-strip__pending') do
      safe_join([
        content_tag(:span, "+#{number} pending", 'aria-hidden': 'true'),
        content_tag(:span, "Plus #{number} #{noun} pending confirmation, not yet in the total.", class: 'sr-only')
      ])
    end
  end

  # The second, contextual ask under the stats: { heading:, body:, button: }.
  # It leans on things a bigger number can't improve: years of reporting, saved books
  # still unreported this year, and keeping the current term up to date.
  def impact_next_prompt(streak_years:, saved_total:, saved_reported:, current_year_reported:)
    reason = 'Every report helps fund new free titles.'

    if !current_year_reported
      body = streak_years.positive? ? "Thank you for #{pluralize(streak_years, 'year')} of reporting. #{reason}" : "It takes about a minute. #{reason}"
      { heading: 'Report this term’s classes to keep your impact current', body: body, button: 'Report an adoption' }
    elsif saved_total > saved_reported
      { heading: "You’ve reported #{saved_reported} of your #{saved_total} saved books this year",
        body: "Teaching with the others this term? Add them here. #{reason}",
        button: 'Count my students' }
    elsif streak_years.positive?
      { heading: "Year #{streak_years + 1} with OpenStax. Thank you for sticking with us.",
        body: "Teaching with another book this term? Add it here. #{reason}",
        button: 'Count my students' }
    else
      { heading: 'Teaching with another book this term?',
        body: "Add it so your impact stays complete. #{reason}",
        button: 'Count my students' }
    end
  end
end
