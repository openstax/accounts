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

      expect(page).to have_select('per_page', selected: '50')
      expect(current_search_query).to eq('ip:"127.0.0.1"')
      expect(current_query_params['per_page']).to eq('50')
    end
  end
end
