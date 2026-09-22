require 'rails_helper'
require 'rake'

describe 'accounts:normalize_salesforce_login_watermarks' do
  include_context 'rake'

  let(:login_time) { 2.days.ago }

  let!(:stranded_student) do
    FactoryBot.create :user, role: :student, last_signed_in_at: login_time,
      salesforce_student_id: 'a0NORM00001', salesforce_student_pushed_at: 1.hour.ago
  end

  let!(:stranded_instructor) do
    FactoryBot.create :user, role: :instructor, last_signed_in_at: login_time,
      salesforce_contact_id: '003NORM0001', salesforce_contact_login_pushed_at: 1.hour.ago
  end

  let!(:correct_student) do
    FactoryBot.create :user, role: :student, last_signed_in_at: login_time,
      salesforce_student_id: 'a0NORM00002', salesforce_student_pushed_at: login_time
  end

  let!(:unlinked_student) do
    FactoryBot.create :user, role: :student, salesforce_student_pushed_at: nil
  end

  it 'moves a stranded student watermark behind the login so it is resent' do
    subject.invoke

    stamp = stranded_student.reload.salesforce_student_pushed_at
    expect(stamp).to be < stranded_student.last_signed_in_at
  end

  it 'clears a stranded Contact watermark' do
    subject.invoke

    expect(stranded_instructor.reload.salesforce_contact_login_pushed_at).to be_nil
  end

  # NULL would queue the user for re-linking by pass 1.
  it 'never leaves a student watermark NULL' do
    subject.invoke

    expect(stranded_student.reload.salesforce_student_pushed_at).not_to be_nil
  end

  it 'leaves a watermark that is already behind the login alone' do
    subject.invoke

    expect(correct_student.reload.salesforce_student_pushed_at).to be_within(1.second).of(login_time)
  end

  it 'leaves never-linked students alone' do
    subject.invoke

    expect(unlinked_student.reload.salesforce_student_pushed_at).to be_nil
  end

  it 'is idempotent' do
    subject.invoke
    subject.reenable
    expect { subject.invoke }.not_to(change { stranded_student.reload.salesforce_student_pushed_at })
  end
end
