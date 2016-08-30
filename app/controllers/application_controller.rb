class ApplicationController < ActionController::Base
  include Lev::HandleWith

  respond_to :html

  layout 'application'

  # skip all filters defined so far
  skip_filter *_process_action_callbacks.map(&:filter), only: [:routing_error]

  include LocaleSelector
  before_filter :set_locale

  def routing_error
    raise ActionController::RoutingError.new(params[:path])
  end
end
