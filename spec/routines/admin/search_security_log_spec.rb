require 'rails_helper'

describe Admin::SearchSecurityLog, type: :routine do

  before(:each) do
    @user = FactoryBot.create :user, first_name: 'Test', last_name: 'User', username: 'TestUser'
    @app = FactoryBot.create :doorkeeper_application, name: 'Some Test App'

    @anon_sl = FactoryBot.create :security_log, user: nil
    @user_sl = FactoryBot.create :security_log, user: @user
    @app_sl = FactoryBot.create :security_log, user: nil, application: @app
    @app_and_user_sl = FactoryBot.create :security_log, user: @user, application: @app

    @another_user = FactoryBot.create :user, first_name: 'Another',
                                              last_name: 'User',
                                              username: 'AnotherUser'
    @another_app = FactoryBot.create :doorkeeper_application, name: 'Another Test App'
    @ip_sl = FactoryBot.create :security_log, user: @another_user,
                                               application: @another_app,
                                               remote_ip: '192.168.0.1'
    @type_sl = FactoryBot.create :security_log, user: @another_user,
                                                 application: @another_app,
                                                 event_type: :admin_created

    @user_with_name_like_other_id = FactoryBot.create :user, first_name: @user.id
    @user_with_name_like_other_id_sl = FactoryBot.create :security_log,
                                                          user: @user_with_name_like_other_id,
                                                          application: @another_app
  end

  it "returns empty results when given empty search strings" do
    [:id, :user_id, :user, :app, :ip, :type, :time, :any].each do |field|
      outputs = described_class.call(query: "#{field}:\"\"").outputs
      expect(outputs.items).to be_empty
      expect(outputs.total_count).to eq 0
    end
  end

  it "matches based on id" do
    items = described_class.call(query: "id:\"#{@anon_sl.id}\"").outputs.items.to_a
    expect(items).to match_array [@anon_sl]
  end

  it "matches based on user id only" do
    items = described_class.call(query: "user_id:#{@user.id}").outputs.items.to_a
    expect(items).to match_array [@app_and_user_sl, @user_sl]
  end

  it "matches based on username" do
    items = described_class.call(query: "user:\"#{@user.username}\"").outputs.items.to_a
    expect(items).to match_array [@app_and_user_sl, @user_sl]
  end

  it "matches based on user's first_name" do
    items = described_class.call(query: "user:\"#{@user.first_name}\"").outputs.items.to_a
    expect(items).to match_array [@app_and_user_sl, @user_sl]
  end

  it "matches anonymous users" do
    items = described_class.call(query: "user:\"anon\"").outputs.items.to_a
    expect(items).to match_array [@anon_sl]
  end

  it "matches application users" do
    items = described_class.call(query: "user:\"app\"").outputs.items.to_a
    expect(items).to match_array [@app_sl]
  end

  it "matches based on app id" do
    items = described_class.call(query: "app:\"#{@app.id}\"").outputs.items.to_a
    expect(items).to match_array [@app_and_user_sl, @app_sl]
  end

  it "matches based on app name" do
    items = described_class.call(query: "app:\"#{@app.name}\"").outputs.items.to_a
    expect(items).to match_array [@app_and_user_sl, @app_sl]
  end

  it "matches accounts" do
    items = described_class.call(query: "app:\"acc\"").outputs.items.to_a
    expect(items).to match_array [@user_sl, @anon_sl]
  end

  it "matches based on ip" do
    items = described_class.call(query: "ip:\"192.168.0\"").outputs.items.to_a
    expect(items).to match_array [@ip_sl]
  end

  it "matches based on type" do
    items = described_class.call(query: "type:\"admin\"").outputs.items.to_a
    expect(items).to match_array [@type_sl]
  end

  it "matches based on time" do
    items = described_class.call(query: "time:\"today\"").outputs.items.to_a
    expect(items).to match_array [@type_sl, @ip_sl, @app_and_user_sl, @app_sl, @user_sl, @anon_sl,
                                  @user_with_name_like_other_id_sl]
  end

  it "matches any fields when no prefix given" do
    items = described_class.call(query: "\"168.0.1,admin\"").outputs.items.to_a
    expect(items).to match_array [@type_sl, @ip_sl]
  end

  it "returns all results in reverse creation order if the query is empty" do
    items = described_class.call(query: '').outputs.items.to_a
    expect(items).to match_array [@user_with_name_like_other_id_sl, @type_sl, @ip_sl,
                                  @app_and_user_sl, @app_sl, @user_sl, @anon_sl]
  end

  describe "numeric type: search (regression for the event_type/event_type_string typo)" do
    it "matches based on a numeric event_type" do
      numeric_type = SecurityLog.event_types['admin_created']

      items = described_class.call(query: "type:\"#{numeric_type}\"").outputs.items.to_a

      expect(items).to match_array [@type_sl]
    end

    it "still falls through to substring matching for non-numeric values" do
      items = described_class.call(query: "type:\"admin\"").outputs.items.to_a

      expect(items).to match_array [@type_sl]
    end
  end

  describe ".sanitize_event_types" do
    it "converts a numeric string directly to its event_type integer" do
      expect(described_class.sanitize_event_types(['34'])).to eq [34]
    end

    it "falls back to substring-matching enum keys for non-numeric strings" do
      matches = described_class.sanitize_event_types(['admin'])

      expect(matches).to match_array(
        SecurityLog.event_types.select { |key, _| key.include?('admin') }.values
      )
    end

    it "returns only the one type for an exact event type name" do
      matches = described_class.sanitize_event_types(['user_updated'])

      expect(matches).to eq [SecurityLog.event_types['user_updated']]
      expect(matches).not_to include(SecurityLog.event_types['user_updated_by_admin'])
    end

    it "combines numeric and exact values" do
      matches = described_class.sanitize_event_types(['34', 'user_updated'])

      expect(matches).to eq [34, SecurityLog.event_types['user_updated']]
    end
  end

  describe "exact event type names" do
    before do
      @updated_sl = FactoryBot.create :security_log, event_type: :user_updated
      @updated_by_admin_sl = FactoryBot.create :security_log, event_type: :user_updated_by_admin
    end

    it "matches only the named type for type:" do
      items = described_class.call(query: 'type:"user_updated"').outputs.items.to_a

      expect(items).to match_array [@updated_sl]
    end

    it "matches only the named type for a bare term" do
      items = described_class.call(query: '"user_updated"').outputs.items.to_a

      expect(items).to match_array [@updated_sl]
    end

    it "still matches every containing type for a partial name" do
      items = described_class.call(query: 'type:"updated"').outputs.items.to_a

      expect(items).to include(@updated_sl, @updated_by_admin_sl)
    end
  end

  describe ".parse_filter_terms" do
    it "returns an empty array for a blank query" do
      expect(described_class.parse_filter_terms(nil)).to eq []
      expect(described_class.parse_filter_terms('')).to eq []
    end

    it "splits a comma-separated value within one keyword into separate terms" do
      terms = described_class.parse_filter_terms('user:"jps,richb"')

      expect(terms).to match_array [
        { keyword: :user, occurrence: 0, value: 'jps' },
        { keyword: :user, occurrence: 0, value: 'richb' }
      ]
    end

    it "keeps separate (space-separated) uses of the same keyword as separate occurrences" do
      terms = described_class.parse_filter_terms('ip:"10.0.0.1" ip:"10.0.0.2"')

      expect(terms).to match_array [
        { keyword: :ip, occurrence: 0, value: '10.0.0.1' },
        { keyword: :ip, occurrence: 1, value: '10.0.0.2' }
      ]
    end

    it "parses multiple distinct keywords" do
      terms = described_class.parse_filter_terms('ip:"10.0.0.1" type:"sign_in_failed"')

      expect(terms).to match_array [
        { keyword: :ip, occurrence: 0, value: '10.0.0.1' },
        { keyword: :type, occurrence: 0, value: 'sign_in_failed' }
      ]
    end
  end

  describe ".remove_filter_term" do
    it "removes only the matching term, leaving the rest of the query intact" do
      query = 'ip:"10.0.0.1" type:"sign_in_failed"'

      result = described_class.remove_filter_term(query, keyword: :ip, occurrence: 0, value: '10.0.0.1')

      expect(result).to eq 'type:"sign_in_failed"'
    end

    it "removes one value from a comma-group without disturbing its siblings" do
      query = 'user:"jps,richb"'

      result = described_class.remove_filter_term(query, keyword: :user, occurrence: 0, value: 'jps')

      expect(result).to eq 'user:"richb"'
    end

    it "returns an empty string when the only term is removed" do
      result = described_class.remove_filter_term('ip:"10.0.0.1"', keyword: :ip, occurrence: 0,
                                                                     value: '10.0.0.1')

      expect(result).to eq ''
    end
  end

  describe ".add_filter_term" do
    it "appends the term to the current query" do
      result = described_class.add_filter_term('user_id:"584"', keyword: :time, value: 'today')

      expect(result).to eq 'user_id:"584" time:"today"'
    end

    it "replaces an existing term of the same keyword and keeps the others in order" do
      query = 'user_id:"584" type:"sign_in_failed" time:"this week" "jps"'

      result = described_class.add_filter_term(query, keyword: :type, value: 'admin')

      expect(result).to eq 'user_id:"584" time:"this week" "jps" type:"admin"'
    end

    it "replaces a comma-separated OR group of the same keyword" do
      result = described_class.add_filter_term('user_id:"584" type:a,b', keyword: 'type', value: 'admin')

      expect(result).to eq 'user_id:"584" type:"admin"'
    end

    it "returns just the new term for a blank query" do
      expect(described_class.add_filter_term(nil, keyword: :ip, value: '10.0.0.1')).to eq 'ip:"10.0.0.1"'
      expect(described_class.add_filter_term('', keyword: :ip, value: '10.0.0.1')).to eq 'ip:"10.0.0.1"'
    end

    it "round-trips through parse_filter_terms" do
      result = described_class.add_filter_term('user_id:584', keyword: :type, value: 'admin')

      terms = described_class.parse_filter_terms(result).map { |t| t.slice(:keyword, :value) }
      expect(terms).to eq [{ keyword: :user_id, value: '584' }, { keyword: :type, value: 'admin' }]
    end
  end
end
