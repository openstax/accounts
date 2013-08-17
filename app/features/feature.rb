
# change this to an included module,
# use 
#   http://ducktypo.blogspot.com/2010/08/why-inheritance-sucks.html
#   http://stackoverflow.com/a/1328093/1664216
module Feature

  def self.included(base)
    base.extend(ClassMethods)
  end

  def call(*args, &block)
    containing_feature.present? ?
      exec(*args, &block) :
      ActiveRecord::Base.transaction {exec(*args, &block)}
  end

  module ClassMethods
    def call(*args, &block)
      new.class(*args, &block)
    end
  end

protected

  attr_accessor :containing_feature

  def run(other_feature, *args, &block)
    other_feature = other_feature.new if other_feature.is_a? Class

    raise IllegalArgument, "A feature can only 'run' another feature" \
      if !(other_feature.included_modules.includes? Feature)

    other_feature.containing_feature = self
    other_feature.call(*args, &block)
  end

end