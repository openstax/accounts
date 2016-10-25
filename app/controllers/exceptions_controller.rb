class ExceptionsController < ActionController::Base

  include LocaleSelector

  skip_filter *_process_action_callbacks.map(&:filter)

  before_filter :set_locale

  def rescue_from
    @exception = env["action_dispatch.exception"]

    OpenStax::RescueFrom.perform_rescue @exception, self
  end

end
