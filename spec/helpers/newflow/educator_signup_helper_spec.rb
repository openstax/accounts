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
  end
end
