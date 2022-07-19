class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_action :authenticate_user!

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

  include Lev::HandleWith

  respond_to :html
end
