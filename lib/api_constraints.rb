class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end
    
  def matches?(req)
    @default || req.headers['Accept'].try(:include?, "application/vnd.exercises.openstax.v#{@version}")
  end
end
