require 'rails_helper'

describe InstructorConnection, type: :model do
  let(:student) { FactoryBot.create(:user, role: :student) }

  it 'defaults to an unverified status' do
    connection = InstructorConnection.create!(
      student: student, instructor_name: 'Sarah Delgado', school_name: 'Rice University'
    )
    expect(connection.status).to eq('unverified')
    expect(connection).to be_unverified
  end

  it 'requires an instructor name' do
    connection = InstructorConnection.new(student: student, school_name: 'Rice University')
    expect(connection).not_to be_valid
    expect(connection.errors[:instructor_name]).to be_present
  end

  it 'requires a school name' do
    connection = InstructorConnection.new(student: student, instructor_name: 'Sarah Delgado')
    expect(connection).not_to be_valid
    expect(connection.errors[:school_name]).to be_present
  end

  it 'rejects an unrecognized status' do
    connection = InstructorConnection.new(
      student: student, instructor_name: 'Sarah Delgado', school_name: 'Rice University', status: 'made_up'
    )
    expect(connection).not_to be_valid
    expect(connection.errors[:status]).to be_present
  end

  it 'can be created without a matched instructor (free-text only)' do
    connection = InstructorConnection.create!(
      student: student, instructor_name: 'Marcus Delgado', school_name: 'University of Houston'
    )
    expect(connection.instructor).to be_nil
  end

  it 'can be linked to a matched instructor and school' do
    school = FactoryBot.create(:school, name: 'Rice University')
    instructor = FactoryBot.create(:user, role: :instructor, faculty_status: :confirmed_faculty, school: school)

    connection = InstructorConnection.create!(
      student: student, instructor: instructor, instructor_name: instructor.name, school: school,
      school_name: school.name
    )

    expect(connection.instructor).to eq(instructor)
    expect(connection.school).to eq(school)
  end
end
