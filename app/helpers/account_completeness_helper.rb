module AccountCompletenessHelper
  # The Overview "profile X% complete" meter. Each item maps to data we
  # already collect elsewhere in the account -- no new fields beyond what
  # LMS answering itself needs (see User#lms_answered?).
  ACCOUNT_COMPLETENESS_ITEMS = [
    { key: :school, label: 'School added' },
    { key: :books, label: 'Books added' },
    { key: :adoption, label: 'Adoption reported' },
    { key: :lms, label: 'Answer LMS question' }
  ].freeze

  def account_completeness_items(user)
    ACCOUNT_COMPLETENESS_ITEMS.map do |item|
      item.merge(done: account_completeness_done?(item[:key], user))
    end
  end

  def account_completeness_summary(user)
    items = account_completeness_items(user)
    done_count = items.count { |item| item[:done] }

    {
      items: items,
      done_count: done_count,
      total_count: items.size,
      percent: items.empty? ? 0 : ((done_count.to_f / items.size) * 100).round
    }
  end

  # One-click jump target for a not-yet-done chip -- the exact tab/field
  # that completes it, per the design's "to-do list, not a score" note.
  def account_completeness_chip_href(key)
    case key
    when :school then account_profile_path(anchor: 'profile-school-field')
    when :books then account_books_path
    when :adoption then account_impact_path
    when :lms then account_overview_path(anchor: 'lms-question-card', show_lms: true)
    end
  end

  private

  def account_completeness_done?(key, user)
    case key
    when :school then user.school.present? || user.self_reported_school.present?
    when :books then user.user_books.exists?
    when :adoption then user.adoptions.exists? || user.adoption_reports.exists?
    when :lms then user.lms_answered?
    end
  end
end
