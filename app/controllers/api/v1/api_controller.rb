module Api
  module V1
    class ApiController < ApplicationController           
      
      include Roar::Rails::ControllerAdditions

      skip_before_filter :authenticate_user!
      respond_to :json
      rescue_from Exception, :with => :rescue_from_exception

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
        send_email = true
    
        case exception
        when SecurityTransgression
          error = :forbidden
          send_email = false
        when ActiveRecord::RecordNotFound, 
             ActionController::RoutingError,
             ActionController::UnknownController,
             AbstractController::ActionNotFound
          error = :not_found
          send_email = false
        end

        ExceptionNotifier::Notifier.exception_notification(
          request.env,
          exception,
          :data => {:message => "An exception occurred"}
        ).deliver if send_email

        Rails.logger.debug("An exception occurred: #{exception.inspect}") if Rails.env.development?

        head error
      end

    end

  end
end