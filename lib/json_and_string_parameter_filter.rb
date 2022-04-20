class JsonAndStringParameterFilter
  def initialize(string_filters, json_key_filters, value_filters)
    @string_filters = string_filters.collect { |f| f.to_s }
    @json_key_filters = json_key_filters.collect { |f| f.to_s }
    @value_filters = value_filters

    @string_regexp = Regexp.new(@string_filters.join('|'), true)
    @json_key_regexp = Regexp.new(@json_key_filters.join('|'), true)
  end

  def filter_data_by_key(data, key_regexp)
    if data.is_a?(Hash)
      data.keys.each do |key|
        if data[key].is_a?(Hash)
          filter_data_by_key(data[key], key_regexp)
        elsif data[key].is_a?(String)
          data[key] = '[FILTERED]' if key =~ key_regexp
        end
      end
    end
  end

  def filter_data_by_value(data, value_filters)
    data.keys.each do |key|
      if data[key].is_a?(Hash)
        filter_data_by_value(data[key], value_filters)
      elsif data[key].is_a?(String)
        value_filters.each do |value_filter|
          data[key] = '[FILTERED]' if value_filter.call(data[key])
        end
      end
    end
  end

  def run(param_key, param_value)
    json_data = JSON.parse(param_key) rescue nil

    if json_data
      filter_data_by_key(json_data, @json_key_regexp)
      filter_data_by_value(json_data, @value_filters)
      param_key.gsub!(/^.*$/, json_data.to_json)
      # no need to do anything with param_value as it's nil
    elsif param_value.is_a?(String)
      if param_key =~ @string_regexp
        utf8_encoded(param_value.gsub!(/^.*$/, '[FILTERED]'))
      else
        @value_filters.each do |value_filter|
          if value_filter.call(utf8_encoded(param_value))
            utf8_encoded(param_value.gsub!(/^.*$/,
'[FILTERED]'))
          end
        end
      end
    elsif param_value.is_a?(Hash)
      filter_data_by_key(param_value, @string_regexp)
      filter_data_by_value(param_value, @value_filters)
    end
  end

  def utf8_encoded(input)
    input.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end
end
