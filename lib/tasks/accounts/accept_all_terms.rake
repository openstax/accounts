require 'accept_all_terms'

namespace :accounts do
  desc 'Accept all terms and licenses for all users'
  task accept_all_terms: [:environment] do
    ::AcceptAllTerms.new.run
  end
end
