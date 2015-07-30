class JsonAndStringParameterFilter
  def initialize(string_filters, json_key_filters)
    @string_filters = string_filters.collect { |f| f.to_s }
    @json_key_filters = json_key_filters.collect { |f| f.to_s }

    @string_regexp = Regexp.new(@string_filters.join('|'), true)
    @json_key_regexp = Regexp.new(@json_key_filters.join('|'), true)
  end

  def run(param_key, param_value)
    json_data = JSON.parse(param_key) rescue nil

    if json_data
      json_data.keys.each do |key|
        json_data[key] = '[FILTERED]' if @json_key_regexp =~ key
      end
      param_key.gsub!(/^.*$/, json_data.to_json)
      # no need to do anything with param_value as it's nil

    elsif @string_regexp =~ param_key
      param_value.gsub!(/^.*$/, '[FILTERED]')
    end
  end
end
