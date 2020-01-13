require 'rails_helper'

module Newflow
  describe ResetPassword, type: :handler do
    it 'creates a login token for user when it has none'

    it 'resets the login token for user when it has one'

    xit 'sends an email to each of the user-s (verified) email addresses' do
      # it doesn't send an email to non-verified email addresses
    end

    context 'when no user found' do
      xit 'results in failure'
    end
  end
end
