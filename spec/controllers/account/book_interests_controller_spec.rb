require 'rails_helper'

RSpec.describe Account::BookInterestsController, type: :controller do
  let(:user) { FactoryBot.create(:user, :terms_agreed, role: :instructor, which_books: 'Biology') }
  let(:other_user) { FactoryBot.create(:user, :terms_agreed, role: :instructor, which_books: 'Astronomy') }
  let(:list_path) { account_books_path(anchor: 'book-interests') }

  before do
    allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
      { subject_name: 'Science', books: [
        { title: 'Biology 2e', salesforce_abbreviation: 'Biology' },
        { title: 'College Physics', salesforce_abbreviation: 'College Physics' },
        { title: 'Q&A <i>Book</i>', salesforce_abbreviation: 'QA' }
      ] }
    ])
    allow(PushBookInterest).to receive(:perform_later)
    allow(Settings::Salesforce).to receive(:push_book_interest_enabled).and_return(true)
  end

  context 'when not signed in' do
    it 'redirects to login and changes nothing' do
      expect(PushBookInterest).not_to receive(:perform_later)

      post :create, params: { abbreviation: 'College Physics' }

      expect(response).to redirect_to(newflow_login_path)
    end
  end

  context 'when signed in' do
    before do
      allow(controller).to receive(:newflow_authenticate_user!).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'refuses edits while the Salesforce push is off, since the next sync would undo them' do
      allow(Settings::Salesforce).to receive(:push_book_interest_enabled).and_return(false)
      expect(PushBookInterest).not_to receive(:perform_later)

      post :create, params: { abbreviation: 'College Physics' }

      expect(response).to redirect_to(list_path)
      expect(user.reload.which_books).to eq('Biology')
    end

    describe '#create' do
      it 'adds the book, tells the user, and enqueues an add delta' do
        expect(PushBookInterest).to receive(:perform_later).with(user: user, add: ['College Physics'], remove: [])

        post :create, params: { abbreviation: 'College Physics' }

        expect(user.reload.which_books).to eq('Biology;College Physics')
        expect(flash[:notice]).to eq('Added College Physics to your interests.')
        expect(response).to redirect_to(list_path)
      end

      it 'writes a security log' do
        expect { post :create, params: { abbreviation: 'College Physics' } }
          .to change { SecurityLog.where(user: user, event_type: :book_interest_changed).count }.by(1)

        expect(SecurityLog.find_by(event_type: :book_interest_changed).event_data)
          .to include('added' => ['College Physics'], 'removed' => [])
      end

      it 'escapes the title in the flash' do
        post :create, params: { abbreviation: 'QA' }

        expect(flash[:notice]).to eq('Added Q&amp;A &lt;i&gt;Book&lt;/i&gt; to your interests.')
      end

      it 'refuses an abbreviation that is not in the catalog' do
        expect(PushBookInterest).not_to receive(:perform_later)

        expect { post :create, params: { abbreviation: 'Not A Book' } }
          .not_to change { SecurityLog.where(event_type: :book_interest_changed).count }

        expect(user.reload.which_books).to eq('Biology')
        expect(flash[:alert]).to eq("We couldn't find that book. Please choose one from the list.")
      end

      it 'refuses a blank abbreviation' do
        post :create, params: { abbreviation: '' }

        expect(flash[:alert]).to be_present
        expect(user.reload.which_books).to eq('Biology')
      end

      it 'does nothing for a book already listed' do
        expect(PushBookInterest).not_to receive(:perform_later)

        post :create, params: { abbreviation: 'Biology' }

        expect(flash[:notice]).to eq('Biology 2e is already in your interests.')
        expect(SecurityLog.where(event_type: :book_interest_changed)).to be_empty
      end
    end

    describe '#destroy' do
      it 'removes the book, tells the user, and enqueues a remove delta' do
        expect(PushBookInterest).to receive(:perform_later).with(user: user, add: [], remove: ['Biology'])

        delete :destroy, params: { abbreviation: 'Biology' }

        expect(user.reload.which_books).to be_nil
        expect(flash[:notice]).to eq('Removed Biology 2e from your interests.')
        expect(SecurityLog.find_by(event_type: :book_interest_changed).event_data)
          .to include('added' => [], 'removed' => ['Biology'])
      end

      it 'removes a value the catalog does not know, naming it by its raw value' do
        user.update!(which_books: 'Biology;Retired Title')

        delete :destroy, params: { abbreviation: 'Retired Title' }

        expect(user.reload.which_books).to eq('Biology')
        expect(flash[:notice]).to eq('Removed Retired Title from your interests.')
      end

      it 'refuses a book that is not on the list' do
        expect(PushBookInterest).not_to receive(:perform_later)

        delete :destroy, params: { abbreviation: 'College Physics' }

        expect(flash[:alert]).to eq("That book isn't on your list.")
        expect(user.reload.which_books).to eq('Biology')
      end

      it 'marks an unsent considering answer sent, but does not change the answer' do
        report = AdoptionReport.create!(user: user, book_title: 'Biology 2e', salesforce_book_name: 'Biology',
                                        school_year: SchoolYear.current, status: 'considering',
                                        source: 'books_status', surface: 'books')

        delete :destroy, params: { abbreviation: 'Biology' }

        expect(report.reload).to have_attributes(status: 'considering')
        expect(report.salesforce_pushed_at).to be_present
      end

      it "only ever touches the signed-in user's own list" do
        other_user

        delete :destroy, params: { abbreviation: 'Astronomy', user_id: other_user.id }

        expect(other_user.reload.which_books).to eq('Astronomy')
        expect(user.reload.which_books).to eq('Biology')
      end
    end

    %i[student self_learner].each do |role|
      context "as a #{role.to_s.tr('_', ' ')}" do
        before { user.update!(role: role) }

        it 'refuses to add' do
          expect(PushBookInterest).not_to receive(:perform_later)

          post :create, params: { abbreviation: 'College Physics' }

          expect(user.reload.which_books).to eq('Biology')
          expect(flash[:alert]).to be_present
        end

        it 'refuses to remove' do
          delete :destroy, params: { abbreviation: 'Biology' }

          expect(user.reload.which_books).to eq('Biology')
        end
      end
    end
  end
end
