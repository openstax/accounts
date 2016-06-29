module I18nMacros
  def t key, *args
      I18n.t key, *args
  end
end

# If we had rails 4+ we could make application raise exception on missing
# translation. Instead we have to check if page has elements with class
# translation_missing which rails 3 inserts on missing translation.
RSpec::Matchers.define :have_no_missing_translations do ||
  include RSpec::Matchers::Composable

  match do |actual|
    actual !~ /class="translation_missing"/
  end

  failure_message do |actual|
    "expected that response would have no missing translations but #{/title="translation missing: (.+?)"/.match(actual)[1]} was missing"
  end
end
