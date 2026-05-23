require 'rails_helper'

module Admin
  describe SalesforceDriftFindingsController, type: :controller do
    let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

    before { controller.sign_in! admin }

    describe 'GET #index' do
      let!(:finding) { FactoryBot.create(:salesforce_drift_finding) }

      it 'lists open findings' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(assigns(:findings)).to include(finding)
      end

      it 'filters by category' do
        FactoryBot.create(:salesforce_drift_finding, category: 'sf_orphan_lead')
        get :index, params: { category: 'sf_orphan_lead' }
        expect(assigns(:findings).map(&:category)).to all(eq('sf_orphan_lead'))
      end

      it 'filters by user_id' do
        user = FactoryBot.create(:user)
        mine = FactoryBot.create(:salesforce_drift_finding, user: user)
        get :index, params: { user_id: user.id }
        expect(assigns(:findings)).to contain_exactly(mine)
      end

      it 'excludes resolved findings' do
        resolved = FactoryBot.create(:salesforce_drift_finding, resolved_at: 1.day.ago)
        get :index
        expect(assigns(:findings)).not_to include(resolved)
      end
    end

    describe 'PATCH #update' do
      let!(:finding) { FactoryBot.create(:salesforce_drift_finding) }

      it 'marks the finding resolved' do
        patch :update, params: { id: finding.id }
        expect(finding.reload.resolved_at).not_to be_nil
      end

      it 'redirects to the index with a notice' do
        patch :update, params: { id: finding.id }
        expect(response).to redirect_to(admin_salesforce_drift_findings_path)
        expect(flash[:notice]).to match(/resolved/i)
      end
    end
  end
end
