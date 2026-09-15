require 'rails_helper'

module Account
  describe CreateInstructorConnection, type: :handler do
    let(:student) { FactoryBot.create(:user, role: :student) }
    let(:school)  { FactoryBot.create(:school, name: 'Rice University') }

    context 'selecting a listed (verified) instructor' do
      let(:instructor) do
        FactoryBot.create(:user, role: :instructor, faculty_status: :confirmed_faculty, school: school,
                                  first_name: 'Sarah', last_name: 'Delgado')
      end

      it 'creates an unverified claim linked to the matched instructor and school' do
        result = described_class.call(caller: student, params: { instructor_connection_form: { instructor_id: instructor.id } })

        expect(result.errors).to be_empty
        connection = result.outputs.instructor_connection
        expect(connection).to be_persisted
        expect(connection.status).to eq('unverified')
        expect(connection.student).to eq(student)
        expect(connection.instructor).to eq(instructor)
        expect(connection.instructor_name).to eq('Sarah Delgado')
        expect(connection.school_name).to eq('Rice University')
        expect(connection.school).to eq(school)
        expect(connection.instructor_email).to be_nil
      end

      it 'rejects an instructor id that is not a verified instructor' do
        unverified = FactoryBot.create(:user, role: :instructor, faculty_status: :pending_faculty)

        result = described_class.call(
          caller: student, params: { instructor_connection_form: { instructor_id: unverified.id } }
        )

        expect(result.errors).not_to be_empty
        expect(InstructorConnection.count).to eq(0)
      end
    end

    context "using the 'my instructor isn't listed' fallback form" do
      let(:params) do
        {
          instructor_connection_form: {
            instructor_name: 'Marcus Delgado',
            school_name: 'University of Houston',
            course: 'BIOL 101',
            term: 'Fall 2026',
            instructor_email: 'marcus@example.edu'
          }
        }
      end

      it 'creates an unverified claim with no matched instructor' do
        result = described_class.call(caller: student, params: params)

        expect(result.errors).to be_empty
        connection = result.outputs.instructor_connection
        expect(connection.instructor).to be_nil
        expect(connection.status).to eq('unverified')
        expect(connection.instructor_name).to eq('Marcus Delgado')
        expect(connection.school_name).to eq('University of Houston')
        expect(connection.course).to eq('BIOL 101')
        expect(connection.term).to eq('Fall 2026')
        expect(connection.instructor_email).to eq('marcus@example.edu')
      end

      it 'fails without an instructor name' do
        result = described_class.call(
          caller: student,
          params: { instructor_connection_form: { school_name: 'Rice University' } }
        )

        expect(result.errors).not_to be_empty
        expect(InstructorConnection.count).to eq(0)
      end
    end

    it 'is not authorized for an anonymous caller' do
      expect {
        described_class.call(
          caller: AnonymousUser.instance,
          params: { instructor_connection_form: { instructor_name: 'X', school_name: 'Y' } }
        )
      }.to raise_error(Lev::SecurityTransgression)
    end

    it 'is not authorized for a non-student caller' do
      expect {
        described_class.call(
          caller: FactoryBot.create(:user, role: :instructor),
          params: { instructor_connection_form: { instructor_name: 'X', school_name: 'Y' } }
        )
      }.to raise_error(Lev::SecurityTransgression)
    end
  end
end
