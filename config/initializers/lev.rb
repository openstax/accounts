Lev.configure do |config|
  config.raise_fatal_errors = false
  config.job_class = ActiveJob::Base
end

###
# 🐒 patch until we define `copy!` in Lev
###
Lev::BetterActiveModelErrors.class_exec do
  def copy!(other)
    ActiveModel::Errors.new(nil).copy!(other)
  end

  def details
    {}
  end
end
