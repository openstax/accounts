module Admin
  class SalesforceDriftFindingsController < BaseController
    def index
      scope = SalesforceDriftFinding.open.includes(:user).order(last_seen_at: :desc)
      scope = scope.where(category: params[:category]) if params[:category].present?
      scope = scope.where(user_id: params[:user_id])   if params[:user_id].present?
      @findings = scope.limit(500)
      @categories = SalesforceDriftFinding.open.distinct.pluck(:category).sort
    end

    def update
      finding = SalesforceDriftFinding.find(params[:id])
      finding.resolve!
      redirect_to admin_salesforce_drift_findings_path, notice: 'Finding marked resolved.'
    end
  end
end
