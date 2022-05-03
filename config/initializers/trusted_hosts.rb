Host.trusted_host_regexes = (Rails.application.secrets[:trusted_hosts] || []).map do |host|
  /\A(.*\.)?#{Regexp.escape host.sub('*.', '').chomp('.*')}\z/
end
