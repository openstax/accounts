require 'rails_helper'

# Exercises the AnnualCheckInGate concern through AccountController's real
# filter chain (rather than re-implementing it), so this proves the gate as
# actually wired, not just the concern in isolation.
RSpec.describe 'AccountController check-in gate', type: :controller do
  controller(AccountController) do
    def index
      render plain: 'ok'
    end

    def create
      render plain: 'ok'
    end
  end

  let(:due_user) do
    FactoryBot.create(:user, :terms_agreed, role: User::INSTRUCTOR_ROLE, created_at: 2.years.ago)
  end

  let(:not_due_user) do
    FactoryBot.create(:user, :terms_agreed, role: User::STUDENT_ROLE)
  end

  it 'lets a non-due user through to the page' do
    controller.sign_in! not_due_user

    get :index

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('ok')
  end

  it 'redirects a due user to the check-in interstitial and stores the destination' do
    UserBook.create!(user: due_user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Bio'))
    controller.sign_in! due_user

    get :index

    expect(response).to redirect_to(account_check_in_path)
  end

  it 'does not gate non-GET requests, so it cannot interpose on a form submission' do
    UserBook.create!(user: due_user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Bio'))
    controller.sign_in! due_user

    post :create

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('ok')
  end
end

RSpec.describe Account::CheckInController, '(gate skip)', type: :controller do
  let(:due_user) do
    user = FactoryBot.create(:user, :terms_agreed, role: User::INSTRUCTOR_ROLE, created_at: 2.years.ago)
    UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Bio'))
    user
  end

  it 'never redirects a due user away from its own show page (no gate loop)' do
    controller.sign_in! due_user

    get :show

    expect(response).to have_http_status(:ok)
  end
end
