require 'rails_helper'
require 'rake'

describe 'accounts:oauth_apps:create_or_update' do
  include_context 'rake'

  let(:admin) { FactoryBot.create :user, :admin }
  let(:app) { FactoryBot.create :doorkeeper_application }

  it 'creates an oauth application' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => 'new app',
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
      'USERNAME' => admin.username,
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]',
      'TRUSTED' => 'true'
    ))
    capture_output do
      expect{subject.invoke}.to(
        output("Created oauth application \"new app\"\n").to_stdout
      )
    end

    new_app = Doorkeeper::Application.order(:id).last
    expect(new_app.name).to eq('new app')
    expect(new_app.redirect_uri).to eq(
      "https://localhost:4000/\r\nhttps://localhost:8000")
    expect(new_app.owner.has_owner? admin).to be true
    expect(new_app.email_from_address).to eq('new-app@example.org')
    expect(new_app.email_subject_prefix).to eq('[new-app]')
    expect(new_app.trusted).to be true
  end

  it 'creates an untrusted oauth application' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => 'new app',
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
      'USERNAME' => admin.username,
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]',
      'TRUSTED' => 'false'
    ))
    expect{subject.invoke}.to output("Created oauth application \"new app\"\n").to_stdout

    new_app = Doorkeeper::Application.order(:id).last
    expect(new_app.name).to eq('new app')
    expect(new_app.redirect_uri).to eq(
      "https://localhost:4000/\r\nhttps://localhost:8000")
    expect(new_app.owner.has_owner? admin).to be true
    expect(new_app.email_from_address).to eq('new-app@example.org')
    expect(new_app.email_subject_prefix).to eq('[new-app]')
    expect(new_app.trusted).to be false
  end

  it 'raises an error if APP_NAME is missing' do
    stub_const('ENV', ENV.to_hash.merge(
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
      'USERNAME' => admin.username,
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]'
    ))
    expect{ subject.invoke }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'raises an error if REDIRECT_URI is missing' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => 'new app',
      'USERNAME' => admin.username,
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]'
    ))
    expect{ subject.invoke }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'raises an error if USERNAME is missing' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => 'new app',
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]'
    ))
    expect{ subject.invoke }.to raise_error(ArgumentError, 'User not found: ')
  end

  it 'raises an error if USERNAME is not found' do
    stub_const('ENV', ENV.to_hash.merge(
      'USERNAME' => 'random',
      'APP_NAME' => 'new app',
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]'
    ))
    expect{ subject.invoke }.to raise_error(ArgumentError, 'User not found: random')
  end

  let(:admin) { FactoryBot.create :user, :admin }
  let(:app) { FactoryBot.create :doorkeeper_application }

  it 'updates an oauth application' do
    stub_const('ENV', ENV.to_hash.merge(
      'USERNAME' => admin.username,
      'APP_NAME' => app.name,
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
      'EMAIL_SUBJECT_PREFIX' => '[new-app]'
    ))
    expect{subject.invoke}.to output("Updated oauth application \"#{app.name}\"\n").to_stdout
    updated_app = Doorkeeper::Application.find_by_name(app.name)
    expect(updated_app.id).to eq(app.id)
    expect(updated_app.uid).to eq(app.uid)
    expect(updated_app.secret).to eq(app.secret)
    expect(updated_app.owner).to_not eq(app.owner)
    expect(updated_app.owner.has_owner? admin).to be true
    expect(updated_app.redirect_uri).to eq(
      "https://localhost:4000/\r\nhttps://localhost:8000")
    expect(updated_app.email_from_address).to eq('new-app@example.org')
    expect(updated_app.email_subject_prefix).to eq('[new-app]')
  end

  it 'updates just the owner' do
    stub_const('ENV', ENV.to_hash.merge(
      'USERNAME' => admin.username,
      'APP_NAME' => app.name,
    ))
    capture_output do
      expect{subject.invoke}.to output("Updated oauth application \"#{app.name}\"\n").to_stdout
    end
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
      'REDIRECT_URI' => 'https://localhost:4000/,https://localhost:8000',
    ))
    capture_output do
      expect{subject.invoke}.to output("Updated oauth application \"#{app.name}\"\n").to_stdout
    end
    updated_app = Doorkeeper::Application.find_by_name(app.name)
    expect(updated_app.id).to eq(app.id)
    expect(updated_app.uid).to eq(app.uid)
    expect(updated_app.secret).to eq(app.secret)
    expect(updated_app.owner).to eq(app.owner)
    expect(updated_app.redirect_uri).to eq(
      "https://localhost:4000/\r\nhttps://localhost:8000")
    expect(updated_app.email_from_address).to eq(app.email_from_address)
    expect(updated_app.email_subject_prefix).to eq(app.email_subject_prefix)
  end

  it 'updates just the email from address' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => app.name,
      'EMAIL_FROM_ADDRESS' => 'new-app@example.org',
    ))
    capture_output do
      expect{subject.invoke}.to output("Updated oauth application \"#{app.name}\"\n").to_stdout
    end
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
    capture_output do
      expect{subject.invoke}.to output("Updated oauth application \"#{app.name}\"\n").to_stdout
    end
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
