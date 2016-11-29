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

    valid_origins = Rails.application.secrets[:valid_iframe_origins] || []
    if valid_origins.any?{|origin| @iframe_parent =~ /^#{origin}/ }
      response.headers.except! 'X-Frame-Options'
    else
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
    true
  end

end
