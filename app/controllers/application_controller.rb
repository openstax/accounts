class ApplicationController < ActionController::Base

  include Lev::HandleWith

  respond_to :html

  protected

  def allow_iframe_access
    @iframe_parent = params[:parent]

    if @iframe_parent.blank?
      response.headers.except! 'X-Frame-Options'
      return true
    end

    if Host.trusted? @iframe_parent
      response.headers.except! 'X-Frame-Options'
    else
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
    true
  end

  def field_error!(on:, code:, message:)
    @errors ||= Lev::Errors.new
    message = I18n.t(message) if message.is_a?(Symbol)
    @errors.add(false, offending_inputs: on, code: code, message: message)
  end

end
