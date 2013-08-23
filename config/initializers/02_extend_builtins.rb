class ActionController::Base
  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  def current_user
    if !request.ssl? || cookies.signed[:secure_user_id] == "secure#{session[:user_id]}"
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
  end
 
  def current_user=(user)
    @current_user = user

    if user.nil?
      session[:user_id] = nil
      cookies.delete(:secure_user_id)
    else
      session[:user_id] = user.id
      cookies.signed[:secure_user_id] = {secure: true, value: "secure#{user.id}"}
    end
  end

  def sign_in(user)
    self.current_user = user
  end

  def sign_out!
    self.current_user = nil
  end

  def signed_in?
    !!current_user
  end

end

# override User#destroy
  # does this constrain what this alg can return? (match destroy return)
  # how to connect into containing algorith transaction? -- single threaded can probably do with global store
  # will need to alias original destroy method so we can call it internally
  # do we disable all of the model's before_destroy and similar?
  # how do we call the override method in time for a user.destroy call? have
  #   to do it in User right? -- use delegate?
  #   or have to put it in something loaded in initializers
  # could say delegate destroy in activerecord::base, have that delegate
  #   to a dynamically created class figured out from the delegated method
  #   and target class -- actually could use our own fancy_delegate method
  #   that would search out the appropriate Algorithm
  #     delegate_to_algorithm :destroy -- if have unconventional algorithm ********* do this
  #     name, let coder specify
  #     we'd need this code to be loaded before the models were loaded I think

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
