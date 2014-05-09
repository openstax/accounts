require 'public_suffix'

# Allows controllers to intercept requests to other controllers,
# do something, then redirect the user back
module Interceptor

  def self.included(base)
    base.class_attribute :is_interceptor
    base.is_interceptor = false
    base.extend(ClassMethods)
  end

  protected

  def current_url
    "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def current_page?(url)
    # Blank is the same page
    url.blank? || URI(url).path == request.path
  end

  def local_url?(url)
    # Blank is local
    return true if url.blank?

    url_host = URI(url).host
    request_host = request.host

    # Looking up the domain on the Public Suffix List is necessary to handle
    # servers in multiple subdomains
    begin
      PublicSuffix.parse(url_host).domain == PublicSuffix.parse(request_host).domain
    rescue PublicSuffix::DomainInvalid
      # We most likely got here because we are using IP addresses instead of
      # named hosts. So just do a direct comparison.
      url_host == request_host
    end
  end

  module ClassMethods

    def interceptor
      return if is_interceptor
      is_interceptor = true

      class_eval do

        helper_method :return_url

        before_filter :set_return_url

        def return_url
          # Only local return urls are allowed
          # Will point to root if non-local
          @return_url ||= local_url?(@unsafe_return_url) ? \
                            @unsafe_return_url : root_url
        end

        def redirect_back(opts = {})
          # Prevent self redirect
          redirect_to (current_page?(return_url) ? root_url : return_url), opts
        end

        # http://stackoverflow.com/a/6239701
        def url_options
          {self.class.return_url_key => return_url}.merge(super)
        end

        protected

        def set_return_url
          @unsafe_return_url = params[self.class.return_url_key] || \
                               session[self.class.return_url_key] || \
                               request.referer || root_url
          session[self.class.return_url_key] = @unsafe_return_url
        end

      end
    end

    def intercept_method_name
      @intercept_method_name ||= "#{controller_name}_intercept"
    end

    def return_url_key
      @return_url_key ||= "#{controller_name}_return_url".to_sym
    end

    def intercept(controller, opts = {}, &blk)
      mname = intercept_method_name
      key = return_url_key

      controller.class_exec(mname, opts, blk, key) do |mname, opts, blk, key|
        before_filter mname, opts

        define_method mname do
          intercept_path = instance_exec &blk

          # Prevent self redirect
          return if !intercept_path || current_page?(intercept_path)

          # Can't redirect back to non-get
          intercepted_url = request.get? ? current_url : root_url

          redirect_to intercept_path, key => intercepted_url
        end
      end
    end

    def skip_intercept(controller, opts = {})
      mname = intercept_method_name

      controller.class_exec(mname, opts) do |mname, opts|
        skip_before_filter mname, opts
      end
    end

  end

end

ActionController::Base.send :include, Interceptor
