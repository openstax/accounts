require 'remove_duplicate_emails'

namespace :accounts do
  desc 'Remove duplicate emails'
  task remove_duplicate_emails: [:environment] do
    ::RemoveDuplicateEmails.new.run(do_it: true)
  end
end
