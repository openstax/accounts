require 'unexpire_all_passwords'

namespace :accounts do
  desc 'Unexpire all passwords for all users'
  task unexpire_all_passwords: [:environment] do
    ::UnexpireAllPasswords.new.run
  end
end
