require 'rails_helper'

feature 'Admin user search', js: true do
  before(:each) do
    @admin_user = create_admin_user
    visit '/'
    complete_newflow_log_in_screen('admin', 'password')
    wait_for_successful_log_in
  end

  def run_search(terms)
    visit '/admin/users'
    fill_in 'user_search_terms', with: terms
    click_button 'Search'
  end

  it 'shows the actual Role in the Role column and the actual school type in the School Type column' do
    user = create_user('role_school_type_user')
    user.update!(first_name: 'Roletest', last_name: 'Schooltype',
                 role: 'instructor', school_type: 'college')

    run_search('name:Roletest')

    expect(page).to have_no_content('We had some unexpected')

    within('tr', text: 'Schooltype') do
      # The old markup labelled the school_type cell "Role" and never rendered the real role.
      expect(page).to have_css('td:nth-child(7)', text: 'Instructor')
      expect(page).to have_no_css('td:nth-child(7)', text: 'College')

      expect(page).to have_css('td:nth-child(9)', text: 'College')
      expect(page).to have_no_css('td:nth-child(9)', text: 'Instructor')
    end
  end

  it 'shows a confirmed and an unconfirmed email distinguishably in the results row' do
    confirmed_user = create_user('confirmed_email_user')
    confirmed_user.update!(first_name: 'Emailtest', last_name: 'Confirmed')
    create_email_address_for(confirmed_user, 'confirmed_test@gmail.com')

    unconfirmed_user = create_user('unconfirmed_email_user')
    unconfirmed_user.update!(first_name: 'Emailtest', last_name: 'Unconfirmed')
    create_email_address_for(unconfirmed_user, 'unconfirmed_test@outlook.com', 'some-confirmation-code')

    run_search('name:Emailtest')

    within('tr', text: 'Confirmed') do
      expect(page).to have_content('confirmed_test@gmail.com')
      expect(page).to have_css('.user-email.confirmed .user-email__badge', text: /\Aconfirmed\z/i)
    end

    within('tr', text: 'Unconfirmed') do
      expect(page).to have_content('unconfirmed_test@outlook.com')
      expect(page).to have_css('.user-email.unconfirmed .user-email__badge', text: /\Anot confirmed\z/i)
    end
  end

  it 'renders an empty state that repeats the query when a search matches nothing' do
    run_search('name:ThisUserDoesNotExistAtAll')

    expect(page).to have_css('.user-search-empty-state')
    expect(page).to have_content('ThisUserDoesNotExistAtAll')
    expect(page).to have_button('search syntax help')
    expect(page).to have_no_css('#search-results-list')
  end

  it 'toggles the expand button aria-expanded state and works from the keyboard' do
    user = create_user('expand_toggle_user')
    user.update!(first_name: 'Expandtest', last_name: 'Toggle')

    run_search('name:Expandtest')

    expand_button = find('button.expand', match: :first)
    expect(expand_button.tag_name).to eq('button')
    expect(expand_button['aria-expanded']).to eq('false')
    expect(page).to have_no_content('UUID:')

    expand_button.send_keys(:space)

    expect(expand_button['aria-expanded']).to eq('true')
    expect(page).to have_content('UUID:')

    expand_button.send_keys(:space)

    expect(expand_button['aria-expanded']).to eq('false')
  end
end
