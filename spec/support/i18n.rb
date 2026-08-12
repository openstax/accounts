module I18nMacros
  def t key, **options
      I18n.t key, **options
  end
end

# If we had rails 4+ we could make application raise exception on missing
# translation. Instead we have to check if page has elements with class
# translation_missing which rails 3 inserts on missing translation.
RSpec::Matchers.define :have_no_missing_translations do ||
  include RSpec::Matchers::Composable

  # Ruby 3.2 removed Object#=~, which `actual !~ regexp` used to fall back to
  # for non-String actuals (always returning nil, i.e. always "matching" --
  # this matcher was silently a no-op for Capybara sessions). Extract the
  # HTML explicitly instead so this actually checks something.
  def html_for(actual)
    actual.respond_to?(:body) ? actual.body : actual.to_s
  end

  match do |actual|
    html_for(actual) !~ /class="translation_missing"/
  end

  failure_message do |actual|
    "expected that response would have no missing translations but #{/title="translation missing: (.+?)"/.match(html_for(actual))[1]} was missing"
  end
end
