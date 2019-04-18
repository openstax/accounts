module OpenStax
  module CloudfrontSimulator
    class Middleware
      def initialize(app, options = {})
        @app = app
      end

      def call(env)
        prefix = OpenStax::PathPrefixer.configuration.prefix
        path = env['PATH_INFO']

        if !path.starts_with?("/assets") && !path.starts_with?("/#{prefix}")
          raise "#{path} not prefixed with Cloudfront path pattern '/#{prefix}'"
        end

        @app.call(env)
      end
    end
  end
end
