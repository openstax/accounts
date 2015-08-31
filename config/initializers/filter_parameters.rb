# Be sure to restart your server when you modify this file.

require 'json_and_string_parameter_filter'

# Filter sensitive data in JSON parameters from logs
#
# JSON parameters are in the key, they look something like this:
# Parameters: {"{\"email\":null,\"username\":\"karen\",\"password\":\"asdfasdf\"}"=>[FILTERED]}
#
# The way the filter parameters work is that first, all the regexp and string
# filters are matched against the key, if it matches, the value is filtered and
# the other filters (proc filters) are NOT run.
#
# See actionpack-3.2.17/lib/action_dispatch/http/parameter_filter.rb
#
# So if we have a string filter "password", the JSON parameter that contains
# "password" will have the value filtered, but the actual sensitive data
# (asdfasdf in the example) is still in the log.
#
# The way to get around this is to remove the string filters and include them
# in the filter proc below.

# First get all the filter parameters
filter_parameters = Rails.application.config.filter_parameters

# Get all the string filter parameters (these are used to match against the key
# of the parameters and filter the value
string_filters = filter_parameters.select { |p| p.is_a?(Symbol) || p.is_a?(String) }

# Get all the non string filter parameters
non_string_filters = filter_parameters - string_filters

# Implement a filter proc that filters out JSON parameters and include existing
# string filters
json_key_filters = [:password]
value_filters = [Proc.new { |value| value =~ /^[^@]+@[^.]+\..+/ }]
filter = JsonAndStringParameterFilter.new(string_filters, json_key_filters, value_filters)

Rails.application.config.filter_parameters = [Proc.new do |k, v|
  filter.run(k, v)
end] + non_string_filters
