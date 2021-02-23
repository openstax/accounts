require 'fix_is_newflow_flag_for_social_users'

namespace :accounts do
  desc 'Fix: users who signed up with Google/Facebook missed the is_neflow flag'
  task fix_is_newflow_flag_for_social_users: [:environment] do
    original_logger = Rails.logger
    begin
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.info 'Starting FixIsNewflowFlagForSocialUsers'
      FixIsNewflowFlagForSocialUsers.call
      Rails.logger.info 'Finished FixIsNewflowFlagForSocialUsers'
    ensure
      Rails.logger = original_logger
    end
  end
end
