require 'rails_helper'

describe 'Log out', type: :feature, js: true do
  scenario 'redirects to caller-specified URL if in whitelist' do
    test_log_out_redirect(url: "https://something.openstax.org/howdy?blah=true", expect_to_redirect_there: true)
  end

  scenario 'does not redirect to a caller-specified URL if not in whitelist' do
    test_log_out_redirect(url: "http://www.google.com", expect_to_redirect_there: false)
  end

  def test_log_out_redirect(url:, expect_to_redirect_there:)
    create_user 'user'

    arrive_from_app
    complete_login_username_or_email_screen('user')
    complete_login_password_screen('password')

    to_or_not_to = expect_to_redirect_there ? :to : :not_to
    expect_any_instance_of(ActionController::Base).send(to_or_not_to, receive(:redirect_to)).with(url, anything())

    visit "/logout?r=#{url}"
  end
end

