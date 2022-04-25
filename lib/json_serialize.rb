module JsonSerialize
  module ClassMethods
    DEFAULT_CONVERSION_METHODS = {
      Array => :to_a,
      Hash => :to_h,
      String => :to_s,
      Integer => :to_i,
      Float => :to_f
    }

    def json_serialize(attribute, type, options = {})
      options[:typecast] = :after_initialize unless options.has_key?(:typecast)
      options[:setter_method] ||= "#{attribute}=".to_sym
      options[:typecast_method] ||= "typecast_#{attribute}".to_sym
      options[:conversion_method] ||= DEFAULT_CONVERSION_METHODS[type]

      serialize attribute, JSON

      send(options[:typecast], options[:typecast_method]) if options[:typecast].present?

      define_method(options[:typecast_method]) do
        return unless has_attribute?(attribute)

        value = send attribute
        return if options[:array] ? value.to_a.all?{ |val| val.is_a? type } : value.is_a?(type)

        raise "Cannot convert object of type #{value.class.name} into #{type.name}" +
              " without specifying the :conversion_method" if options[:conversion_method].nil?

        typecast_value = options[:array] ? \
                           value.to_a.map(&options[:conversion_method]) :
                           value.send(options[:conversion_method])
        send options[:setter_method], typecast_value
      end

      protected options[:typecast_method]

    end
  end
end

# Validator to go along with JsonSerialize
class MaxJsonLengthValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if record[attribute].to_s.length > options[:with]
      # This may break in rails 7 per
      # https://docs.rubocop.org/rubocop-rails/cops_rails.html#railsdeprecatedactivemodelerrorsmethods
      record.errors[attribute] << (options[:message] || "is too long") # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
    end
  end

end

ActiveRecord::Base.extend JsonSerialize::ClassMethods
