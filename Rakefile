# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

ENV['RAILS_ENV'] = 'test' if ARGV[0] == 'parallel:spec'

begin
  require 'rspec/core/rake_task'

  namespace :spec do
    desc 'Run the fast code examples'
    RSpec::Core::RakeTask.new(:fast) do |t|
      t.rspec_opts = %w[--tag ~speed:slow]
    end

    desc 'Run the slow code examples'
    RSpec::Core::RakeTask.new(:slow) do |t|
      t.rspec_opts = %w[--tag speed:slow]
    end

    desc 'Run the fast code examples first, then the slow code examples'
    task speed: %w[spec:fast spec:slow]
  end
rescue LoadError
end

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

# Used by error_page_assets gem. We override it because of the path prefix.
def process_error_files
  config = Rails.configuration
  pattern = File.join(config.paths['public'].first, 'accounts', 'assets', "[0-9][0-9][0-9]*.html")

  groups = Dir[pattern].group_by { |s| File.basename(s)[0..2] }.sort_by { |base, _| base }

  [ '', 'accounts' ].each do |prefix|
    groups.each do |base, group|
      src = group.sort_by { |f| File.mtime(f) }.last
      dst = Rails.public_path.join(prefix, "#{base}.html").to_s
      yield src, dst
    end
  end
end
