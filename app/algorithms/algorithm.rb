
#   http://ducktypo.blogspot.com/2010/08/why-inheritance-sucks.html
#   http://stackoverflow.com/a/1328093/1664216
module Algorithm

  def self.included(base)
    base.extend(ClassMethods)
  end

  def call(*args, &block)
    containing_algorithm.present? ?
      exec(*args, &block) :
      ActiveRecord::Base.transaction {exec(*args, &block)}
  end

  module ClassMethods
    def call(*args, &block)
      new.call(*args, &block)
    end

    # def override(klass_and_method, options={})
    #   # self is the algorithm to call
    #   klass, method = klass_and_method.split('#')

    #   klass = Kernel.const_get(klass)
    #   method = method.to_sym

    #   algorithm_klass = self

    #   klass.instance_eval do 
    #     define_method method do
    #       # self here is User
    #       debugger
    #       algorithm_klass.call(klass)
    #       puts 'in fake destroy'
    #     end
    #   end
    #   puts method
    # end
  end

protected

  attr_accessor :containing_algorithm

  def run(other_algorithm, *args, &block)
    other_algorithm = other_algorithm.new if other_algorithm.is_a? Class

    raise IllegalArgument, "A algorithm can only 'run' another algorithm" \
      if !(other_algorithm.eigenclass.included_modules.include? Algorithm)

    other_algorithm.containing_algorithm = self
    other_algorithm.call(*args, &block)
  end

end
