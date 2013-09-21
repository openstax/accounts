class ActionController::Base
  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  # Always return an object
  def current_user
    if !request.ssl? || cookies.signed[:secure_user_id] == "secure#{session[:user_id]}"
      @current_user ||= AnonymousUser.instance

      if @current_user.is_anonymous? && session[:user_id]
        # Use current_user= to clear out bad state if any
        self.current_user = User.where(id: session[:user_id]).first
      end

      @current_user
    end
  end
 
  def current_user=(user)
    @current_user = user || AnonymousUser.instance
    if @current_user.is_anonymous?
      session[:user_id] = nil
      cookies.delete(:secure_user_id)
    else
      session[:user_id] = @current_user.id
      cookies.signed[:secure_user_id] = {secure: true, value: "secure#{@current_user.id}"}
    end
    @current_user
  end

  def sign_in(user)
    self.current_user = user
  end

  def sign_out!
    self.current_user = AnonymousUser.instance
  end

  def signed_in?
    !current_user.is_anonymous?
  end

end

# ActiveRecord::Base.delegate_to_algorithm
#
# Let active records delegate certain (likely non-trivial) actions to algoritms
# 
# Arguments:
#   method: a symbol for the instance method to delegate, e.g. :destroy
#   options: a hash of options including...
#      :algorithm_klass => The class of the algorithm to delegate to; if not 
#        given, 
ActiveRecord::Base.define_singleton_method(:delegate_to_algorithm) do |method, options={}|
  algorithm_klass = options[:algorithm_klass]

  if algorithm_klass.nil?
    algorithm_klass_name = "#{method.to_s.capitalize}#{self.name}"
    algorithm_klass = Kernel.const_get(algorithm_klass_name)
  end

  self.instance_eval do
    alias_method "#{method}_original".to_sym, method
    define_method method do
      algorithm_klass.call(self)
    end
  end

end
