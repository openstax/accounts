module Api
  module V1
    class ApiController < ApplicationController           
      
      include Roar::Rails::ControllerAdditions

      skip_before_filter :authenticate_user!

      fine_print_skip_signatures :general_terms_of_use,
                                 :privacy_policy

      respond_to :json
      rescue_from Exception, :with => :rescue_from_exception

      def self.api_example(options={})
        return if Rails.env.test?
        raise IllegalArgument, "must supply a :url parameter" if !options[:url_base]

        url_base = options[:url_base].is_a?(Symbol) ?
                     UrlGenerator.new.send(options[:url_base], protocol: 'https') :
                     options[:url_base].to_s
        
        "#{url_base}/#{options[:url_end] || ''}"
      end

      #
      # There is a method and supporting code here for generating JSON schemas 
      # from Representers; one day we'll put these in a library or somewhere 
      # more formal, but they are not ready yet.
      #

      def self.json_schema(representer, options={})
        options[:indent] ||= FUNKY_INDENT_CHARS

"
Schema  {##{SecureRandom.hex(4)} .schema}
------
<pre class='code'>
#{RepresentableSchemaPrinter.json(representer, options)}
</pre>
"
      end

      class RepresentableSchemaPrinter

        def self.json(representer, options={})
          options[:include] ||= [:readable, :writeable]
          options[:indent] ||= '  '

          definitions = {}

          schema = json_schema(representer, definitions, options)
          schema[:definitions] = definitions

          JSON.pretty_generate(schema, {indent: options[:indent]})
        end

      protected

        def self.json_schema(representer, definitions, options={})
          schema = {
            # id: schema_id(representer),
            # title: schema_title(representer),
            type: "object",
            properties: {},
            required: []
            # :$schema => "http://json-schema.org/draft-04/schema#"
          }

          representer.representable_attrs.each do |attr|
            schema_info = attr.options[:schema_info] || {}

            schema[:required].push(attr.name) if schema_info[:required]

            next unless [options[:include]].flatten.any?{|inc| attr.send(inc.to_s+"?") || schema_info[:required]}
            
            attr_info = {}

            if attr.options[:collection]
              attr_info[:type] = "array"
            else
              attr_info[:type] = attr.options[:type].to_s.downcase if attr.options[:type]
            end

            schema_info.each do |key, value|
              next if [:required].include?(key)
              value = value.to_s.downcase if key == :type
              attr_info[key] = value
            end

            decorator = attr.options[:decorator].try(:is_a?, Proc) ? nil : attr.options[:decorator]

            if decorator
              relative_schema_id(decorator).tap do |id|
                attr_info[:$ref] = "#/definitions/#{id}"
                definitions[id] ||= json_schema(decorator, definitions, options)
              end
            end

            schema[:properties][attr.name.to_sym] = attr_info
          end

          schema
        end

        def self.schema_title(representer)
          representer.name.gsub(/Representer/,'')
        end

        def self.schema_id(representer)
          "http://exercises.openstax.org/#{schema_title(representer).downcase.gsub(/::/,'/')}"
        end

        def self.relative_schema_id(representer)
          representer.name.gsub(/Representer/,'').downcase.gsub(/::/,'/')
        end

      end
     
      
    protected

      def rescue_from_exception(exception)
        # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
        error = :internal_server_error
        notify = true
    
        case exception
        when SecurityTransgression
          error = :forbidden
          notify = false
        when ActiveRecord::RecordNotFound, 
             ActionController::RoutingError,
             ActionController::UnknownController,
             AbstractController::ActionNotFound
          error = :not_found
          notify = false
        end

        if notify
          ExceptionNotifier.notify_exception(
            exception,
            env: request.env,
            data: { message: "An exception occurred" }
          )

          Rails.logger.error("An exception occurred: #{exception.message}\n\n#{exception.backtrace.join("\n")}") \
        end
        
        head error
      end

    end

  end
end