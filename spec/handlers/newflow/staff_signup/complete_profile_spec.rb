require 'rails_helper'

module Newflow
  module StaffSignup

    describe CompleteProfile, type: :handler do
      let(:user) { create_user('staffuser', 'password', :terms_agreed) }
      let(:handle) { described_class.handle(params: params, user: user) }

      let(:staff_role) { 'librarian' }
      let(:other_role_name) { nil }
      let(:books_involved) { [] }
      let(:num_learners_supported) { '400' }
      let(:params) do
        {
          signup: {
            school_name: 'Rice University',
            staff_role: staff_role,
            other_role_name: other_role_name,
            books_involved: books_involved,
            num_learners_supported: num_learners_supported
          }
        }
      end

      before(:each) do
        disable_sfdc_client
        allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
      end

      context 'with valid params' do
        it 'does not error' do
          result = handle
          expect(result.errors).to be_empty
        end

        it 'maps the role to a User#role enum value and stores the literal label' do
          handle
          user.reload
          expect(user.role).to eq('librarian')
          expect(user.other_role_name).to eq('Librarian')
        end

        it 'marks the profile complete but leaves faculty_status untouched' do
          handle
          user.reload
          expect(user.is_profile_complete?).to be true
          expect(user.faculty_status).to eq(User::NO_FACULTY_INFO)
        end

        it 'never sends staff through SheerID (no verification id set)' do
          handle
          user.reload
          expect(user.sheerid_verification_id).to be_blank
        end

        it 'stores the reported number of learners supported' do
          handle
          user.reload
          expect(user.how_many_students).to eq('400')
        end

        context 'two role options that collapse to the same enum value' do
          let(:staff_role) { 'department_chair' }

          it 'stores administrator with the specific label' do
            handle
            user.reload
            expect(user.role).to eq('administrator')
            expect(user.other_role_name).to eq('Department chair')
          end
        end

        context 'lms_it_administrator' do
          let(:staff_role) { 'lms_it_administrator' }

          it 'also maps to administrator, distinguished by other_role_name' do
            handle
            user.reload
            expect(user.role).to eq('administrator')
            expect(user.other_role_name).to eq('LMS / IT administrator')
          end
        end

        context 'curriculum_coordinator' do
          let(:staff_role) { 'curriculum_coordinator' }

          it 'maps to designer' do
            handle
            user.reload
            expect(user.role).to eq('designer')
            expect(user.other_role_name).to eq('Curriculum coordinator')
          end
        end

        context 'homeschool_educator' do
          let(:staff_role) { 'homeschool_educator' }

          it 'maps to homeschool' do
            handle
            user.reload
            expect(user.role).to eq('homeschool')
            expect(user.other_role_name).to eq('Homeschool educator')
          end
        end

        context 'other, with free text' do
          let(:staff_role) { 'other' }
          let(:other_role_name) { '  Grant writer  ' }

          it 'stores the free-text role, stripped' do
            handle
            user.reload
            expect(user.role).to eq('other')
            expect(user.other_role_name).to eq('Grant writer')
          end
        end

        context 'school selection via school_id' do
          let(:school) { FactoryBot.create(:school, name: 'Rice University', city: 'Houston', state: 'TX') }
          let(:params) do
            {
              signup: {
                school_name: 'rice univ',
                school_id: school.id,
                staff_role: staff_role,
                books_involved: books_involved,
                num_learners_supported: num_learners_supported
              }
            }
          end

          it 'links the School and stores its canonical name' do
            handle
            user.reload
            expect(user.school).to eq(school)
            expect(user.self_reported_school).to eq('Rice University')
          end
        end

        context 'with books involved' do
          let(:books_involved) { ['Psych2e', 'Sociology2e'] }

          it 'stores the selected books as a semicolon-joined string, like the educator flow' do
            handle
            user.reload
            expect(user.which_books).to eq('Psych2e;Sociology2e')
          end
        end

        context 'with no books selected' do
          let(:books_involved) { [] }

          it 'leaves which_books blank' do
            handle
            user.reload
            expect(user.which_books).to be_blank
          end
        end
      end

      context 'with invalid params' do
        context 'school name is blank' do
          let(:params) do
            { signup: { staff_role: staff_role, books_involved: [], num_learners_supported: num_learners_supported } }
          end

          it 'returns a validation error' do
            result = handle
            expect(result.errors.any? { |e| e.code == :school_name }).to be true
          end
        end

        context 'other role selected without free text' do
          let(:staff_role) { 'other' }
          let(:other_role_name) { '' }

          it 'returns a validation error' do
            result = handle
            expect(result.errors.any? { |e| e.code == :other_role_name }).to be true
          end
        end

        context 'unrecognized staff_role' do
          let(:staff_role) { 'wizard' }

          it 'returns a validation error' do
            result = handle
            expect(result.errors).not_to be_empty
          end
        end

        context 'number of learners supported is blank' do
          let(:num_learners_supported) { '' }

          it 'returns a validation error' do
            result = handle
            expect(result.errors.any? { |e| e.code == :num_learners_supported }).to be true
          end
        end

        context 'number of learners supported is not a number' do
          let(:num_learners_supported) { 'many' }

          it 'returns a validation error' do
            result = handle
            expect(result.errors.any? { |e| e.code == :num_learners_supported }).to be true
          end
        end
      end

      context 'salesforce lead push' do
        it 'pushes a lead when enabled' do
          expect(CreateOrUpdateSalesforceLead).to receive(:perform_later).with(user: user)
          handle
        end

        it 'does not push a lead when disabled' do
          allow(Settings::Salesforce).to receive(:push_leads_enabled) { false }
          expect(CreateOrUpdateSalesforceLead).not_to receive(:perform_later)
          handle
        end
      end
    end
  end
end
