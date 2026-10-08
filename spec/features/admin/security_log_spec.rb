require 'rails_helper'

feature 'Admin security log page', js: true do
  before(:each) do
    @admin_user = create_admin_user
    visit '/'
    complete_newflow_log_in_screen('admin', 'password')
    wait_for_successful_log_in
  end

  def current_query_params
    Rack::Utils.parse_nested_query(URI.parse(page.current_url).query)
  end

  def current_search_query
    current_query_params.dig('search', 'query')
  end

  context 'with a user that has a name and email' do
    let!(:target_user) do
      user = FactoryBot.create(:user, first_name: 'Jamie', last_name: 'Rivera')
      FactoryBot.create(:email_address, user: user, value: 'jamie.rivera@example.com')
      user
    end

    let!(:target_log) do
      FactoryBot.create(:security_log, user: target_user, remote_ip: '10.0.0.5',
                                       event_type: :sign_in_failed,
                                       event_data: { reason: 'bad_password' })
    end

    it 'shows the user id, name, and email, linked to the user edit page' do
      visit admin_security_log_path

      row = find('#security-log-table tr', text: target_user.name)

      expect(row).to have_link("##{target_user.id}", href: edit_admin_user_path(target_user))
      expect(find_link("##{target_user.id}")['target']).to eq('_blank')
      expect(row).to have_content('jamie.rivera@example.com')
    end

    it 'expands and collapses the event data for a row' do
      visit admin_security_log_path

      expect(page).to have_no_content('"reason": "bad_password"')

      row = find('#security-log-table tr', text: target_user.name)
      row.find('.expand').click

      expect(page).to have_content('"reason": "bad_password"')

      row.find('.expand').click

      expect(page).to have_no_content('"reason": "bad_password"')
    end

    it 'filters by clicking the type cell' do
      visit admin_security_log_path

      click_link 'Sign in failed'

      expect(current_search_query).to eq('type:"sign_in_failed"')
      expect(page).to have_content('Sign in failed')
    end

    it 'filters by clicking the IP cell' do
      visit admin_security_log_path

      click_link '10.0.0.5'

      expect(current_search_query).to eq('ip:"10.0.0.5"')
      expect(page).to have_content('10.0.0.5')
    end

    it 'filters by clicking the user cell' do
      visit admin_security_log_path

      click_link target_user.name

      expect(current_search_query).to eq(%(user_id:"#{target_user.id}"))
      expect(page).to have_content(target_user.name)
    end
  end

  context 'entries missing the values the cells link on' do
    # link_to renders its href as the link text when the name is blank, which
    # turned an entry logged outside a request into a row displaying a URL.
    it 'shows a placeholder instead of a link when there is no remote ip' do
      FactoryBot.create(:security_log, remote_ip: nil, event_type: :user_became_activated)

      visit admin_security_log_path

      expect(page).to have_no_content('admin/security_log?search')
      expect(find('#security-log-table tbody tr', match: :first)).to have_content('—')
    end

    it 'labels a user with no name rather than linking the filter url' do
      nameless = FactoryBot.create(:user, first_name: nil, last_name: nil, username: nil)
      FactoryBot.create(:security_log, user: nameless, remote_ip: '10.0.0.9')

      visit admin_security_log_path

      expect(page).to have_no_content('admin/security_log?search')
      expect(page).to have_link('(no name)')
    end
  end

  context 'escaping event data' do
    let(:xss_payload) { '<script>window.xssFired = true</script>' }

    let!(:xss_log) do
      FactoryBot.create(:security_log, user: nil,
                                       event_type: :unknown,
                                       event_data: { note: xss_payload })
    end

    it 'renders event data as escaped text instead of executing it' do
      visit admin_security_log_path

      row = find('#security-log-table tr', text: 'Anonymous')
      row.find('.expand').click

      expect(page).to have_content('<script>window.xssFired = true</script>')
      expect(page.evaluate_script('window.xssFired')).to be_falsey
    end
  end

  context 'per-page selector' do
    before do
      25.times { FactoryBot.create(:security_log, user: nil) }
    end

    it 'round-trips the current query when changing per_page' do
      visit admin_security_log_path(search: { query: 'ip:"127.0.0.1"' })

      select '50', from: 'per_page'
      click_button 'Apply'

      expect(page).to have_select('per_page', selected: '50')
      expect(current_search_query).to eq('ip:"127.0.0.1"')
      expect(current_query_params['per_page']).to eq('50')
    end

    it 'does not auto-submit merely from selecting a per_page option (WCAG 3.2.2)' do
      visit admin_security_log_path
      starting_url = page.current_url

      select '50', from: 'per_page'

      expect(page.current_url).to eq(starting_url)
    end
  end

  context 'per-page clamping' do
    before do
      25.times { FactoryBot.create(:security_log, user: nil) }
    end

    it 'clamps an out-of-range per_page to the default instead of passing it through' do
      visit admin_security_log_path(per_page: '999999')

      expect(page).to have_select('per_page', selected: '20')
    end

    it 'clamps a non-numeric per_page to the default' do
      visit admin_security_log_path(per_page: 'abc')

      expect(page).to have_select('per_page', selected: '20')
    end
  end

  context 'expand all / collapse all' do
    before do
      3.times { FactoryBot.create(:security_log, user: nil) }
    end

    it 'expands and collapses every row, flipping its own label and each row aria-expanded' do
      visit admin_security_log_path

      row_count = page.all('.expand', visible: :all).size
      expect(row_count).to be >= 3

      expect(page).to have_button('Expand all')
      expect(page).to have_no_css('.expand[aria-expanded="true"]')

      click_button 'Expand all'

      expect(page).to have_button('Collapse all')
      expect(page).to have_css('.expand[aria-expanded="true"]', count: row_count)

      click_button 'Collapse all'

      expect(page).to have_button('Expand all')
      expect(page).to have_no_css('.expand[aria-expanded="true"]')
    end
  end

  context 'active filter chips' do
    let!(:log_a) { FactoryBot.create(:security_log, user: nil, remote_ip: '10.0.0.1') }
    let!(:log_b) { FactoryBot.create(:security_log, user: nil, remote_ip: '10.0.0.2') }

    it 'shows a readable chip for a query term and removes only that term' do
      visit admin_security_log_path(search: { query: %(ip:"10.0.0.1" type:"sign_in_failed") })

      expect(page).to have_css('.filter-chip', text: 'IP 10.0.0.1')
      expect(page).to have_css('.filter-chip', text: 'Type Sign in failed')

      within('.filter-chip', text: 'IP 10.0.0.1') { click_link '×' }

      expect(current_search_query).to eq('type:"sign_in_failed"')
      expect(page).to have_no_css('.filter-chip', text: 'IP 10.0.0.1')
      expect(page).to have_css('.filter-chip', text: 'Type Sign in failed')
    end

    it 'renders nothing when there is no active query' do
      visit admin_security_log_path

      expect(page).to have_no_css('.security-log-filter-chips')
    end
  end

  context 'empty results' do
    it 'names the active query and points to the search syntax help' do
      visit admin_security_log_path(search: { query: 'ip:"192.0.2.123"' })

      expect(page).to have_content('No security log entries match')
      expect(page).to have_content('ip:"192.0.2.123"')
      expect(page).to have_link('search syntax help')
    end
  end
end
