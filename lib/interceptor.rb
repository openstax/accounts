# Allows controllers to intercept requests to other controllers,
# do something, then redirect the user back
module Interceptor

  def self.included(base)
    base.extend(ClassMethods)
    base.helper_method :return_url
  end

  def return_url
    session[self.class.return_url_param]
  end

  def redirect_back
    url = return_url
    url = root_path if !url || url == current_url
    redirect_to url
  end

  module ClassMethods

    def intercept_method_name
      @intercept_method_name ||= "#{controller_name}_intercept"
    end

    def return_url_param
      @return_url_param ||= "#{controller_name}_return_url"
    end

    def intercept(controller, options = {}, &block)
      controller.class_exec(intercept_method_name, options, block,
                            return_url_param) do |name, opts, block, param|
        before_filter name, opts

        define_method name do
          intercept_path = instance_exec &block
          if intercept_path
            session[param] = current_url
            redirect_to intercept_path
          else
            session.delete(param)
          end
        end
      end
    end

    def skip_intercept(controller, options = {})
      controller.class_exec(intercept_method_name, options) do |name, opts|
        skip_before_filter name, opts
      end
    end

  end

end