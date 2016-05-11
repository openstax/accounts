require 'rails_helper'

describe Admin::SearchSecurityLog, type: :routine do

  let!(:user)            { FactoryGirl.create :user, first_name: 'Test', last_name: 'User' }
  let!(:app)             { FactoryGirl.create :doorkeeper_application }

  let!(:anon_sl)         { FactoryGirl.create :security_log, user: nil }
  let!(:user_sl)         { FactoryGirl.create :security_log, user: user }
  let!(:app_sl)          { FactoryGirl.create :security_log, user: nil, application: app }
  let!(:app_and_user_sl) { FactoryGirl.create :security_log, user: user, application: app }

  let!(:another_app)     { FactoryGirl.create :doorkeeper_application }
  let!(:ip_sl)           { FactoryGirl.create :security_log, application: another_app,
                                                             remote_ip: '192.168.0.1' }
  let!(:type_sl)         { FactoryGirl.create :security_log, application: another_app,
                                                             event_type: :admin_created }

  it "matches based on id" do
    items = described_class.call(query: "id:\"#{anon_sl.id}\"").outputs.items.to_a
    expect(items).to eq [anon_sl]
  end

  it "matches based on user id" do
    items = described_class.call(query: "user:\"#{user.id}\"").outputs.items.to_a
    expect(items).to eq [app_and_user_sl, user_sl]
  end

  it "matches based on username" do
    items = described_class.call(query: "user:\"#{user.username}\"").outputs.items.to_a
    expect(items).to eq [app_and_user_sl, user_sl]
  end

  it "matches based on user's first_name" do
    items = described_class.call(query: "user:\"#{user.first_name}\"").outputs.items.to_a
    expect(items).to eq [app_and_user_sl, user_sl]
  end

  it "matches anonymous users" do
    items = described_class.call(query: "user:\"anon\"").outputs.items.to_a
    expect(items).to eq [anon_sl]
  end

  it "matches application users" do
    items = described_class.call(query: "user:\"app\"").outputs.items.to_a
    expect(items).to eq [app_sl]
  end

  it "matches based on app id" do
    items = described_class.call(query: "app:\"#{app.id}\"").outputs.items.to_a
    expect(items).to eq [app_and_user_sl, app_sl]
  end

  it "matches based on app name" do
    items = described_class.call(query: "app:\"#{app.name}\"").outputs.items.to_a
    expect(items).to eq [app_and_user_sl, app_sl]
  end

  it "matches accounts" do
    items = described_class.call(query: "app:\"acc\"").outputs.items.to_a
    expect(items).to eq [user_sl, anon_sl]
  end

  it "matches based on ip" do
    items = described_class.call(query: "ip:\"192.168.0\"").outputs.items.to_a
    expect(items).to eq [ip_sl]
  end

  it "matches based on type" do
    items = described_class.call(query: "type:\"admin\"").outputs.items.to_a
    expect(items).to eq [type_sl]
  end

  it "matches any fields when no prefix given" do
    items = described_class.call(query: "\"168.0.1\" \"admin\"").outputs.items.to_a
    expect(items).to eq [type_sl, ip_sl]
  end

  it "returns all results in reverse creation order if the query is empty" do
    items = described_class.call(query: '').outputs.items.to_a
    expect(items).to eq [type_sl, ip_sl, app_and_user_sl, app_sl, user_sl, anon_sl]
  end

end
