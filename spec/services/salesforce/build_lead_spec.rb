require 'rails_helper'

RSpec.describe Salesforce::BuildLead do
  let(:school) do
    FactoryBot.create(:school,
      salesforce_id: 'SF1', name: 'Rice', city: 'Houston',
      country: 'United States', state: 'Texas')
  end

  let(:user) do
    FactoryBot.create(:user,
      role: 'instructor', first_name: 'A', last_name: 'B',
      phone_number: '+15555555555', who_chooses_books: 'instructor',
      which_books: 'AP Macro Econ', how_many_students: '50',
      using_openstax_how: 'as_primary', expected_start_semester: 'next_semester',
      receive_newsletter: true, school: school, faculty_status: 'pending_faculty',
      is_profile_complete: true)
  end

  let(:lead) { Salesforce::Records::Lead.new(email: 'a@b.com') }

  before do
    allow(user).to receive(:books_used_details).and_return(
      { 'Calculus Volume 1' => { 'num_students_using_book' => 50, 'how_using_book' => 'Required' } }
    )
  end

  it 'maps role=instructor to Instructor and copies role into position' do
    described_class.apply(lead, user)
    expect(lead.role).to eq('Instructor')
    expect(lead.position).to eq('instructor')
  end

  it 'maps role=student to Student with nil position' do
    user.update!(role: 'student')
    described_class.apply(lead, user)
    expect(lead.role).to eq('Student')
    expect(lead.position).to be_nil
  end

  it 'always sets accounts_uuid (invariant for retry idempotency)' do
    described_class.apply(lead, user)
    expect(lead.accounts_uuid).to eq(user.uuid)
  end

  it 'builds adoption_json for non-as_future users' do
    described_class.apply(lead, user)
    parsed = JSON.parse(lead.adoption_json)
    expect(parsed['Books']).to be_an(Array)
    expect(parsed['Books'].first).to include('name' => 'Calculus Volume 1', 'students' => 50)
  end

  it 'skips adoption_json when using_openstax_how is as_future' do
    user.update!(using_openstax_how: 'as_future')
    described_class.apply(lead, user)
    expect(lead.adoption_json).to be_nil
  end

  it 'maps US state full name to lead.state' do
    described_class.apply(lead, user)
    expect(lead.state).to eq('Texas')
  end

  it 'maps US state abbreviation (uppercase) to lead.state_code' do
    school.update!(state: 'TX')
    described_class.apply(lead, user)
    expect(lead.state_code).to eq('TX')
  end

  it 'maps adoption_status from using_openstax_how' do
    described_class.apply(lead, user)
    expect(lead.adoption_status).to eq('Confirmed Adoption Won')
  end

  it 'sets verification_status to faculty_status when not no_faculty_info' do
    described_class.apply(lead, user)
    expect(lead.verification_status).to eq('pending_faculty')
  end

  it 'sets verification_status to nil when faculty_status is no_faculty_info' do
    user.update!(faculty_status: 'no_faculty_info')
    described_class.apply(lead, user)
    expect(lead.verification_status).to be_nil
  end
end
