require 'spec_helper'
require 'rake'

describe 'accounts:oauth_apps rake tasks' do
  before :all do
    Rake::Task['accounts:oauth_apps:create'] rescue Accounts::Application.load_tasks
  end

  describe 'accounts:oauth_apps:create' do
    let(:admin) { FactoryGirl.create :user, :admin }
    let(:app) { FactoryGirl.create :doorkeeper_application }

    before :each do
      Rake::Task['accounts:oauth_apps:create'].reenable
      Rake::Task['accounts:oauth_apps:update'].reenable
    end

    it 'creates an oauth application' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => 'new app',
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
        'USERNAME' => admin.username,
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]',
        'TRUSTED' => 'true'
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:create'].invoke
      end
      expect(stdout).to eq("Created oauth application \"new app\"\n")
      expect(stderr).to be_empty

      new_app = Doorkeeper::Application.order(:id).last
      expect(new_app.name).to eq('new app')
      expect(new_app.redirect_uri).to eq(
        "http://localhost:4000/\r\nhttp://localhost:8000")
      expect(new_app.owner.has_owner? admin).to be true
      expect(new_app.email_from_address).to eq('new-app@example.org')
      expect(new_app.email_subject_prefix).to eq('[new-app]')
      expect(new_app.trusted).to be true
    end

    it 'creates an untrusted oauth application' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => 'new app',
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
        'USERNAME' => admin.username,
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]',
        'TRUSTED' => 'false'
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:create'].invoke
      end
      expect(stdout).to eq("Created oauth application \"new app\"\n")
      expect(stderr).to be_empty

      new_app = Doorkeeper::Application.order(:id).last
      expect(new_app.name).to eq('new app')
      expect(new_app.redirect_uri).to eq(
        "http://localhost:4000/\r\nhttp://localhost:8000")
      expect(new_app.owner.has_owner? admin).to be true
      expect(new_app.email_from_address).to eq('new-app@example.org')
      expect(new_app.email_subject_prefix).to eq('[new-app]')
      expect(new_app.trusted).to be false
    end

    it 'raises an error if APP_NAME is missing' do
      stub_const('ENV', ENV.to_hash.merge(
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
        'USERNAME' => admin.username,
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]'
      ))
      expect {
        Rake::Task['accounts:oauth_apps:create'].invoke
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises an error if REDIRECT_URI is missing' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => 'new app',
        'USERNAME' => admin.username,
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]'
      ))
      expect {
        Rake::Task['accounts:oauth_apps:create'].invoke
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises an error if USERNAME is missing' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => 'new app',
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]'
      ))
      expect {
        Rake::Task['accounts:oauth_apps:create'].invoke
      }.to raise_error(ArgumentError, 'User not found: ')
    end

    it 'raises an error if USERNAME is not found' do
      stub_const('ENV', ENV.to_hash.merge(
        'USERNAME' => 'random',
        'APP_NAME' => 'new app',
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]'
      ))
      expect {
        Rake::Task['accounts:oauth_apps:create'].invoke
      }.to raise_error(ArgumentError, 'User not found: random')
    end

    it 'updates an oauth application' do
      stub_const('ENV', ENV.to_hash.merge(
        'USERNAME' => admin.username,
        'APP_NAME' => app.name,
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
        'EMAIL_SUBJECT_PREFIX' => '[new-app]'
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:update'].invoke
      end
      expect(stdout).to eq("Updated oauth application \"#{app.name}\"\n")
      updated_app = Doorkeeper::Application.find_by_name(app.name)
      expect(updated_app.id).to eq(app.id)
      expect(updated_app.uid).to eq(app.uid)
      expect(updated_app.secret).to eq(app.secret)
      expect(updated_app.owner).to_not eq(app.owner)
      expect(updated_app.owner.has_owner? admin).to be true
      expect(updated_app.redirect_uri).to eq(
        "http://localhost:4000/\r\nhttp://localhost:8000")
      expect(updated_app.email_from_address).to eq('new-app@example.org')
      expect(updated_app.email_subject_prefix).to eq('[new-app]')
    end

    it 'updates just the owner' do
      stub_const('ENV', ENV.to_hash.merge(
        'USERNAME' => admin.username,
        'APP_NAME' => app.name,
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:update'].invoke
      end
      expect(stdout).to eq("Updated oauth application \"#{app.name}\"\n")
      updated_app = Doorkeeper::Application.find_by_name(app.name)
      expect(updated_app.id).to eq(app.id)
      expect(updated_app.uid).to eq(app.uid)
      expect(updated_app.secret).to eq(app.secret)
      expect(updated_app.owner).to_not eq(app.owner)
      expect(updated_app.owner.has_owner? admin).to be true
      expect(updated_app.redirect_uri).to eq(app.redirect_uri)
      expect(updated_app.email_from_address).to eq(app.email_from_address)
      expect(updated_app.email_subject_prefix).to eq(app.email_subject_prefix)
    end

    it 'updates just the redirect uri' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => app.name,
        'REDIRECT_URI' => 'http://localhost:4000/,http://localhost:8000',
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:update'].invoke
      end
      expect(stdout).to eq("Updated oauth application \"#{app.name}\"\n")
      updated_app = Doorkeeper::Application.find_by_name(app.name)
      expect(updated_app.id).to eq(app.id)
      expect(updated_app.uid).to eq(app.uid)
      expect(updated_app.secret).to eq(app.secret)
      expect(updated_app.owner).to eq(app.owner)
      expect(updated_app.redirect_uri).to eq(
        "http://localhost:4000/\r\nhttp://localhost:8000")
      expect(updated_app.email_from_address).to eq(app.email_from_address)
      expect(updated_app.email_subject_prefix).to eq(app.email_subject_prefix)
    end

    it 'updates just the email from address' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => app.name,
        'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:update'].invoke
      end
      expect(stdout).to eq("Updated oauth application \"#{app.name}\"\n")
      updated_app = Doorkeeper::Application.find_by_name(app.name)
      expect(updated_app.id).to eq(app.id)
      expect(updated_app.uid).to eq(app.uid)
      expect(updated_app.secret).to eq(app.secret)
      expect(updated_app.owner).to eq(app.owner)
      expect(updated_app.redirect_uri).to eq(app.redirect_uri)
      expect(updated_app.email_from_address).to eq('new-app@example.org')
      expect(updated_app.email_subject_prefix).to eq(app.email_subject_prefix)
    end

    it 'updates just the email subject prefix' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => app.name,
        'EMAIL_SUBJECT_PREFIX' => '[new-app]'
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:update'].invoke
      end
      expect(stdout).to eq("Updated oauth application \"#{app.name}\"\n")
      updated_app = Doorkeeper::Application.find_by_name(app.name)
      expect(updated_app.id).to eq(app.id)
      expect(updated_app.uid).to eq(app.uid)
      expect(updated_app.secret).to eq(app.secret)
      expect(updated_app.owner).to eq(app.owner)
      expect(updated_app.redirect_uri).to eq(app.redirect_uri)
      expect(updated_app.email_from_address).to eq(app.email_from_address)
      expect(updated_app.email_subject_prefix).to eq('[new-app]')
    end
  end

  describe 'accounts:oauth_apps:list' do
    let!(:tutor) { FactoryGirl.create :doorkeeper_application, name: 'OpenStax Tutor' }
    let!(:biglearn) { FactoryGirl.create :doorkeeper_application, name: 'OpenStax Biglearn' }

    before :each do
      Rake::Task['accounts:oauth_apps:list'].reenable
    end

    it 'lists all application names, tokens and secrets' do
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:list'].invoke
      end
      expect(stdout).to eq(
        "OpenStax Biglearn: #{biglearn.uid} #{biglearn.secret}\n" <<
        "OpenStax Tutor: #{tutor.uid} #{tutor.secret}\n"
      )
    end

    it 'displays one application if APP_NAME is given' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => 'OpenStax biglearn'
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:list'].invoke
      end
      expect(stdout).to eq(
        "OpenStax Biglearn: #{biglearn.uid} #{biglearn.secret}\n"
      )
    end

    it 'displays a warning message if app is not found' do
      stub_const('ENV', ENV.to_hash.merge(
        'APP_NAME' => 'not found'
      ))
      stdout, stderr = capture_output do
        Rake::Task['accounts:oauth_apps:list'].invoke
      end
      expect(stdout).to eq("No applications found.\n")
    end
  end
end
