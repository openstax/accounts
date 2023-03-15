class TermsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :pose_by_name, :agree]
  skip_before_action :complete_signup_profile, only: [:index, :show]

  before_action :authenticate_user_with_token!, :allow_iframe_access, only: [:pose_by_name, :agree]
  before_action :get_contract, only: [:show]

  fine_print_skip :general_terms_of_use, :privacy_policy

  def index
    @contracts = [FinePrint.get_contract(:general_terms_of_use),
                  FinePrint.get_contract(:privacy_policy)].compact
    if @contracts.length != 2
      redirect_to root_path, alert: (I18n.t :"controllers.terms.temporarily_unavailable")
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

  def pose_by_name
    @contract = FinePrint::Contract.published.latest.find_by! params[:name]
    render :pose
  end

  def agree
    handle_with(
      TermsAgree, complete: -> do
        params[:r].present? && Host.trusted?(params[:r]) ?
          redirect_to(params[:r]) : fine_print_return
      end
    )
  end

  protected

  def authenticate_user_with_token!
    if params[:token].present?
      token = Doorkeeper::AccessToken.find_by token: params[:token]
      return head(:forbidden) if token.nil?
      @current_user = token.user
    else
      authenticate_user!
    end
  end

  def get_contract
    @contract = FinePrint.get_contract(params[:id])
  end
end
