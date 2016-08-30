module LocaleSelector
  # Parses an Accept-Language header as described by Section
  # {5.3.5 of RFC 7231}[https://tools.ietf.org/html/rfc7231#section-5.3.5],
  # strips variant selectors and returns list of language tags as symbols
  # sorted descending by weight.
  def parse_accept_language accept_language
    accept_language.split(',').map do |e|
      return [] unless /\A\s*([a-zA-Z-]+)(?:;q=([0-9]+(?:\.[0-9]+)?))?\s*\Z/ =~ e
      [$1.to_sym, ($2 || 1).to_f]
    end.keep_if do |x|
      I18n.available_locales.include? x[0]
    end.sort {|a, b| b[1] <=> a[1] }
       .map {|x| x[0] }
  end

  # Sets locale based on information provided by the browser, defaulting to
  # I18n.default_locale.
  def set_locale
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE'] || ''
    I18n.locale = (parse_accept_language accept_language).first || I18n.default_locale
  end
end
