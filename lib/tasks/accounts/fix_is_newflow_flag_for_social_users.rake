require 'fix_is_newflow_flag_for_social_users'

namespace :accounts do
  desc 'Fix: users who signed up with Google/Facebook missed the is_neflow flag'
  task fix_is_newflow_flag_for_social_users: [:environment] do
    FixIsNewflowFlagForSocialUsers.call
  end
end
