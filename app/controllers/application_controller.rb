class ApplicationController < ActionController::Base
  include Lev::HandleWith

  respond_to :html

  layout 'application_body_only'

  # skip all filters defined so far
  skip_filter *_process_action_callbacks.map(&:filter), only: [:routing_error]

  before_filter :set_locale

  def routing_error
    raise ActionController::RoutingError.new(params[:path])
  end

  # Sets locale based on information provided by the browser, defaulting to
  # I18n.default_locale.
  def set_locale
    accepts = request.env['HTTP_ACCEPT_LANGUAGE'].split(',').map do |e|
      v = e.split ';'
      lang = v[0].split('-')[0]
      q = 1 == v.size ? 1 : v[1].to_f
      [lang.to_sym, q]
    end.keep_if do |x|
      I18n.available_locales.include? x[0]
    end.sort {|a, b| b[1] <=> a[1] }.map {|x| x[0] }
    I18n.locale = accepts.first || I18n.default_locale
  end
end
