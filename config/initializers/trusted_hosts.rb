Host.trusted_host_regexes = Rails.application.secrets.trusted_hosts.map do |host|
  if host.start_with?('*.')
    wildcard_regex_prefix = '(.*\\.)?'
    host_without_beginning_wildcard = host.sub('*.', '')
  else
    wildcard_regex_prefix = ''
    host_without_beginning_wildcard = host
  end

  /\A#{wildcard_regex_prefix}#{Regexp.escape host_without_beginning_wildcard.chomp('.*')}\z/
end
