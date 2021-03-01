require 'rails_helper'

describe 'whenever schedule' do
  let (:schedule) { Whenever::Test::Schedule.new(file: 'config/schedule.rb') }

  context 'basics' do
    before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }

    it 'makes sure `runner` statements exist' do
      assert_equal 2, schedule.jobs[:runner].count

      expect_any_instance_of(UpdateUserSalesforceInfo).to receive(:call)

      # Executes the actual ruby statement to make sure all constants and methods exist:
      schedule.jobs[:runner].each { |job| eval job[:task] }
    end
  end

  context 'UpdateUserSalesforceInfo' do
    context 'error emails' do
      before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }
      around(:each) { |example| use_local_zone(example) }

      it 'does not send error emails at 5pm' do
        Timecop.freeze(Chronic.parse("5 pm")) do
          expect(::UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: false)
          schedule.jobs[:runner].each { |job| eval job[:task] }
        end
      end

      it 'does send error emails in the midnight hour\'s first run' do
        Timecop.freeze(Chronic.parse("12:09 am")) do
          expect(::UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: true)
          schedule.jobs[:runner].each { |job| eval job[:task] }
        end
      end

      it 'does not send error emails in the midnight hour after the first run' do
        Timecop.freeze(Chronic.parse("12:11 am")) do
          expect(::UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: false)
          schedule.jobs[:runner].each { |job| eval job[:task] }
        end
      end
    end
  end

  def use_local_zone(example)
    begin
      original_time_class = Chronic.time_class
      Chronic.time_class = Time.zone
      example.run
    ensure
      Chronic.time_class = original_time_class
    end
  end

  def eval_runner_tasks(regex)
    schedule.jobs[:runner].each { |job| eval job[:task] if job[:task].match(regex)}
  end

end
