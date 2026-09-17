require 'rails_helper'

feature 'User updates profile', js: true do
  before(:each) do
    mock_current_user(create_user('user'))
    visit '/i/profile'
  end

  describe 'Updating name' do
    before(:each) do
      find('#name').click
    end

    scenario 'first name' do
      fill_in 'first_name', with: 'testuser'
      screenshot!
      find('.glyphicon-ok').click
      expect(page).to have_button('testuser')
      screenshot!
    end

    # Removed tests for blank names because names are now required
    scenario 'name with spaces' do
      fill_in 'last_name', with: '  '
      find('.glyphicon-ok').click
      expect(find('.editable-error-block').text).to include (t :"javascript.name.last_name_blank")
      screenshot!
    end

  end

  describe 'Updating self-reported school' do
    before(:each) do
      FactoryBot.create :school, name: 'Rice University', city: 'Houston', state: 'TX'

      find('#self-reported-school').click
    end

    scenario 'picking a suggested school' do
      fill_in 'school_name', with: 'Rice'

      expect(page).to have_css('.school-autocomplete-results li', text: 'Rice University')

      find('.school-autocomplete-results li', text: 'Rice University', match: :first).click
      find('.glyphicon-ok').click

      expect(page).to have_button('Rice University')
      screenshot!
    end

    scenario 'typing a school name not in the list' do
      fill_in 'school_name', with: 'Hogwarts Academy'

      expect(page).to have_css('.school-autocomplete-use-as-entered', text: 'Hogwarts Academy')

      find('.school-autocomplete-use-as-entered').click
      find('.glyphicon-ok').click

      expect(page).to have_button('Hogwarts Academy')
      screenshot!
    end

    scenario 'reopening the editor does not duplicate the autocomplete list' do
      find('.editable-cancel').click
      find('#self-reported-school').click

      # Reopening alone can't duplicate anything: x-editable's prerender()
      # re-parses $tpl into a fresh container on every show, and the inline
      # container empties itself on cancel. The guard is against a second
      # attach on a container that is still live, so force that directly.
      page.execute_script(
        "OxSchoolAutocomplete.attach(document.querySelector('.school-autocomplete'));"
      )

      fill_in 'school_name', with: 'Rice'

      expect(page).to have_css('.school-autocomplete-results', count: 1, visible: :all)
      expect(page).to have_css(
        '.school-autocomplete-results li', text: 'Rice University', count: 1, visible: :all
      )
      screenshot!
    end
  end
end
