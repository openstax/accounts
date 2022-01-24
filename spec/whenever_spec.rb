require 'rails_helper'

RSpec.describe 'whenever schedule' do
  let(:schedule) { Whenever::Test::Schedule.new(file: 'config/schedule.rb') }

  context 'basics' do
    before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }

    it 'makes sure `rake` statements exist' do
      salesforce_jobs = schedule.jobs[:rake].select do |job|
        [ 'cron:10-to-half-hour', 'cron:5-past-half-hour' ].include? job[:task]
      end
      expect(salesforce_jobs.count).to eq 2

      expect_any_instance_of(UpdateUserContactInfo).to receive(:call)
      expect_any_instance_of(UpdateSchoolSalesforceInfo).to receive(:call)

      # Executes the actual rake tasks to make sure all constants and methods exist:
      salesforce_jobs.each do |job|
        task = Rake::Task[job[:task]]
        task.reenable
        task.invoke
      end
    end
  end

  # context 'UpdateUserSalesforceInfo' do
  #   context 'error emails' do
  #     before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }
  #     around(:each) { |example| use_local_zone(example) }
  #
  #     it 'does not send error emails at 5pm' do
  #       Timecop.freeze(Chronic.parse("5 pm")) do
  #         expect(::UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: false)
  #         invoke_rake_tasks 'cron:5-past-half-hour'
  #       end
  #     end
  #
  #     it 'does send error emails in the midnight hour\'s first run' do
  #       Timecop.freeze(Chronic.parse("12:09 am")) do
  #         expect(::UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: true)
  #         invoke_rake_tasks 'cron:5-past-half-hour'
  #       end
  #     end
  #
  #     it 'does not send error emails in the midnight hour after the first run' do
  #       Timecop.freeze(Chronic.parse("12:11 am")) do
  #         expect(::UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: false)
  #         invoke_rake_tasks 'cron:5-past-half-hour'
  #       end
  #     end
  #   end
  # end

  def use_local_zone(example)
    begin
      original_time_class = Chronic.time_class
      Chronic.time_class = Time.zone
      example.run
    ensure
      Chronic.time_class = original_time_class
    end
  end

  def invoke_rake_tasks(regex)
    schedule.jobs[:rake].select { |job| job[:task].match?(regex) }.each do |job|
      task = Rake::Task[job[:task]]
      task.reenable
      task.invoke
    end
  end
end
