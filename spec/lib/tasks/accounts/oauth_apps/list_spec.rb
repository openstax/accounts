require 'rails_helper'
require 'rake'

describe 'accounts:oauth_apps:list' do
  include_context 'rake'

  let!(:tutor) { FactoryGirl.create :doorkeeper_application, name: 'OpenStax Tutor' }
  let!(:biglearn) { FactoryGirl.create :doorkeeper_application, name: 'OpenStax Biglearn' }

  it 'lists all application names, tokens and secrets' do
    capture_output do
      expect{subject.invoke}.to(
        output("OpenStax Biglearn: #{biglearn.uid} #{biglearn.secret}\n" +
               "OpenStax Tutor: #{tutor.uid} #{tutor.secret}\n").to_stdout
      )
    end
  end

  it 'displays one application if APP_NAME is given' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => 'OpenStax biglearn'
    ))
    capture_output do
      expect{subject.invoke}.to(
        output("OpenStax Biglearn: #{biglearn.uid} #{biglearn.secret}\n").to_stdout
      )
    end
  end

  it 'displays a warning message if app is not found' do
    stub_const('ENV', ENV.to_hash.merge(
      'APP_NAME' => 'not found'
    ))
    capture_output do
      expect{subject.invoke}.to output("No applications found.\n").to_stdout
    end
  end
end
