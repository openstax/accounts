class TermsController < ApplicationController
  before_action :get_contract, only: [:show]

  def index
    @contracts = [FinePrint.get_contract(:general_terms_of_use),
                  FinePrint.get_contract(:privacy_policy)].compact
    if @contracts.length != 2
      redirect_to root_path, alert: (I18n.t :'controllers.terms.temporarily_unavailable')
    end
  end

  def show
    # Hide old agreements (should never get them)
    raise ActiveRecord::RecordNotFound \
      if !@contract.is_latest? && !current_user.is_administrator?

    # Prevent routing error email when accessing this route for HTML format
    respond_to do |format|
      format.js
      format.html
    end
  end

  def pose
    @contract = FinePrint.get_contract(params[:terms].first)
  end

  def agree
    handle_with(TermsAgree, complete: lambda { fine_print_return })
  end

  protected

  def get_contract
    @contract = FinePrint.get_contract(params[:id])
  end
end
