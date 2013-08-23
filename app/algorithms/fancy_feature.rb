

# currently not used, just playing around
class FancyFeature

  

  def call(*args, &block)
    begin
      exec(*args, &block)
      check_queued_rules
      save_queued_objects
    rescue RuleError => e

    end
  end

  def self.run(other_feature, *args, &block)
    Feature.new.run(other_feature, *args, &block)
  end



protected

  attr_accessor :containing_feature

  def run(other_feature, *args, &block)
    other_feature = other_feature.new if other_feature.is_a? Class

    raise IllegalArgument, "A feature can only 'run' another feature" \
      if !(other_feature.is_a? Feature)

    other_feature.containing_feature = self
    other_feature.call(*args, &block)
  end

  def check_rule_now(rule=nil, &block)
    # Really need to pass up things check now?
    return @containing_feature.check_rule_now(rule, &block) if @containing_feature
    (rule || BlockRule.new(&block)).check
  end

  def check_rule_later(rule=nil, &block)
    return @containing_feature.check_rule_later(rule, &block) if @containing_feature

    @rules_queue ||= []
    @rules_queue.push(rule || BlockRule.new(&block))
  end

  def persist_later(&block)
    return @containing_feature.change_state_later(object) if @containing_feature
  end

  def save_later(object)
    return @containing_feature.save_later(object) if @containing_feature

    @objects_to_save ||= []
    @objects_to_save.push(object)
  end

  def check_queued_rules
    @rules_queue.each do |rule|
      rule.check
    end
  end

  def save_queued_objects
    ActiveRecord::Base.transaction do
      @objects_to_save.each{|object| object.save!}
    end
  end

  ###########

  def check_before_state_changes(&block)
  end

  def change_state(&block)
  end

  def check_pre_state_change_rules

  end


end