require 'rails_helper'

RSpec.describe Admin::SearchSecurityLog, type: :routine do

  before(:each) do
    @user = FactoryGirl.create :user, first_name: 'Test', last_name: 'User', username: 'TestUser'
    @app = FactoryGirl.create :doorkeeper_application, name: 'Some Test App'

    @anon_sl = FactoryGirl.create :security_log, user: nil
    @user_sl = FactoryGirl.create :security_log, user: @user
    @app_sl = FactoryGirl.create :security_log, user: nil, application: @app
    @app_and_user_sl = FactoryGirl.create :security_log, user: @user, application: @app

    @another_user = FactoryGirl.create :user, first_name: 'Another',
                                              last_name: 'User',
                                              username: 'AnotherUser'
    @another_app = FactoryGirl.create :doorkeeper_application, name: 'Another Test App'
    @ip_sl = FactoryGirl.create :security_log, user: @another_user,
                                               application: @another_app,
                                               remote_ip: '192.168.0.1'
    @type_sl = FactoryGirl.create :security_log, user: @another_user,
                                                 application: @another_app,
                                                 event_type: :admin_created

    @user_with_name_like_other_id = FactoryGirl.create :user, first_name: @user.id
    @user_with_name_like_other_id_sl = FactoryGirl.create :security_log,
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

end
