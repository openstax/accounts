require 'rails_helper'

module Newflow
  describe EducatorSignupHelper, type: :helper do
    describe '#educator_copy_audience' do
      before { allow(helper).to receive(:current_user).and_return(current_user) }

      %w[k12_school high_school home_school].each do |school_type|
        context "when user has school_type '#{school_type}'" do
          let(:current_user) { instance_double(User, school_type: school_type) }

          it 'returns :k12' do
            expect(helper.educator_copy_audience).to eq :k12
          end
        end
      end

      %w[college other_school_type unknown_school_type].each do |school_type|
        context "when user has school_type '#{school_type}'" do
          let(:current_user) { instance_double(User, school_type: school_type) }

          it 'returns :default' do
            expect(helper.educator_copy_audience).to eq :default
          end
        end
      end

      context 'when school_type is nil' do
        let(:current_user) { instance_double(User, school_type: nil) }

        it 'returns :default' do
          expect(helper.educator_copy_audience).to eq :default
        end
      end

      context 'when there is no current user' do
        let(:current_user) { nil }

        it 'returns :default' do
          expect(helper.educator_copy_audience).to eq :default
        end
      end
    end

    describe '#educator_copy' do
      before { allow(helper).to receive(:educator_copy_audience).and_return(audience) }

      around do |example|
        I18n.backend.store_translations(:en, educator_profile_form: {
          instructor: 'Instructor',
          researcher: 'Researcher',
          k12: { instructor: 'K-12 Teacher' }
        })
        example.run
        I18n.reload!
      end

      context 'when audience is :k12 and a scoped override exists' do
        let(:audience) { :k12 }

        it 'returns the scoped value' do
          expect(helper.educator_copy(:instructor)).to eq 'K-12 Teacher'
        end
      end

      context 'when audience is :k12 but no scoped override exists for the key' do
        let(:audience) { :k12 }

        it 'falls back to the default value' do
          expect(helper.educator_copy(:researcher)).to eq 'Researcher'
        end
      end

      context 'when audience is :default' do
        let(:audience) { :default }

        it 'returns the default value' do
          expect(helper.educator_copy(:instructor)).to eq 'Instructor'
        end
      end
    end

    describe '#current_email_looks_personal?' do
      before do
        allow(helper).to receive(:current_user).and_return(current_user)
      end

      context 'when the on-file email is a personal address' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: 'j.delgado@gmail.com') }

        it 'returns true' do
          expect(helper.current_email_looks_personal?).to eq true
        end
      end

      context 'when the on-file email ends in .edu' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: 'j.delgado@rice.edu') }

        it 'returns false' do
          expect(helper.current_email_looks_personal?).to eq false
        end
      end

      context 'when the on-file email ends in .org' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: 'j.delgado@myschool.org') }

        it 'returns false' do
          expect(helper.current_email_looks_personal?).to eq false
        end
      end

      context 'when there is no on-file email yet' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: nil) }

        it 'returns false' do
          expect(helper.current_email_looks_personal?).to eq false
        end
      end
    end

    describe '#show_school_email_gate?' do
      before do
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper).to receive(:session).and_return(session)
      end

      let(:session) { {} }

      context 'when the on-file email looks personal and the gate has not been skipped' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: 'j.delgado@gmail.com') }

        it 'returns true' do
          expect(helper.show_school_email_gate?).to eq true
        end
      end

      context 'when the on-file email already looks like a school email' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: 'j.delgado@rice.edu') }

        it 'returns false' do
          expect(helper.show_school_email_gate?).to eq false
        end
      end

      context 'when the user has chosen to use their current (personal) email anyway' do
        let(:current_user) { instance_double(User, best_email_address_for_salesforce: 'j.delgado@gmail.com') }
        let(:session) { { Newflow::EducatorSignupHelper::SKIP_SCHOOL_EMAIL_GATE_SESSION_KEY => true } }

        it 'returns false' do
          expect(helper.show_school_email_gate?).to eq false
        end
      end
    end
  end
end
