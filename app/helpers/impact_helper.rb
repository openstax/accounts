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
      return 'You haven’t reported any adoptions for this period yet. Reporting helps keep your OpenStax story current and highlights the students you support.'
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
        "Over #{period_text}, your reported adoptions have supported ",
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
      'You’ve kept your adoption story current across multiple academic years — thank you.'
    elsif students >= 300
      'You’ve supported hundreds of students through your reported adoptions.'
    elsif books >= 3
      'Your reported adoptions span multiple titles — that visibility matters.'
    else
      "Every reported adoption helps reflect real classroom use and support OpenStax's mission."
    end
  end

  def impact_countup_value(value, format = 'integer')
    return impact_currency_brief(value) if format == 'currency'

    number_with_delimiter(value.to_i)
  end

  def formatted_currency_compact(value)
    impact_currency_brief(value)
  end

  def milestone_chips(stats)
    chips = []
    years = stats[:years].to_i
    students = stats[:students].to_i
    savings = stats[:savings].to_f
    books = stats[:books].to_i

    chips << 'First year reported' if years == 1 && students.positive?
    chips << '3+ years reported' if years >= 3
    chips << '100+ students supported' if students >= 100
    chips << '500+ students supported' if students >= 500
    chips << '$10K+ estimated student savings' if savings >= 10_000
    chips << 'Multiple books reported' if books >= 3

    chips.compact.uniq.first(3)
  end

  def impact_summary_sentence(view_mode, stats, current_school_year)
    if view_mode == 'current'
      if stats[:students].to_i.positive?
        books = stats[:books].to_i
        books_label = books == 1 ? 'book' : 'books'
        students = number_with_delimiter(stats[:students].to_i)
        "This year, you reported #{students} students supported across #{books} #{books_label}."
      else
        "Add this year’s adoptions to keep your #{current_school_year} impact up to date."
      end
    else
      students = number_with_delimiter(stats[:students].to_i)
      savings = formatted_currency_compact(stats[:savings])
      "Over time, you reported #{students} students supported and about #{savings} in estimated student savings."
    end
  end

  def impact_moment_line(view_mode, has_adoptions, stats, current_school_year)
    if view_mode == 'current'
      if has_adoptions
        "Thanks for sharing your #{current_school_year} adoptions—your updates help us champion your students."
      else
        'When you report this year’s adoptions, we can highlight your impact and support you faster.'
      end
    else
      'Thanks for keeping your adoption story current across multiple academic years.'
    end
  end

  def impact_badge_subtext(timestamp)
    if timestamp.present?
      "Last reported #{timestamp.strftime('%b %-d, %Y')}"
    else
      'Report this year to get started'
    end
  end
end
