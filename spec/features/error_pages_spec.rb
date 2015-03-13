require 'spec_helper'

feature 'Show error pages', js: true do
  scenario 'for internal server error 500' do
    with_error_pages do
      visit '/admin/raise_exception/not_yet_implemented'
      expect(page.status_code).to eq(500)
      expect(page).to have_content('500 Internal Server Error')
    end
  end

  scenario 'for not found 404' do
    with_error_pages do
      visit '/admin/raise_exception/routing_error'
      expect(page.status_code).to eq(404)
      expect(page).to have_content('404 Not Found')
    end
  end

  scenario 'for forbidden 403' do
    with_error_pages do
      visit '/admin/raise_exception/security_transgression'
      expect(page.status_code).to eq(403)
      expect(page).to have_content('403 Forbidden')
    end
  end
end
