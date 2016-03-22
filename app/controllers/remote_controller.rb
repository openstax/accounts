class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:iframe, :notify_logout]
  skip_before_filter :finish_sign_up,     only: [:iframe]
  skip_before_filter :expired_password,   only: [:iframe]
  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:iframe]

  before_filter :validate_iframe_parent, :only=>[:iframe, :notify_logout]

  layout false

  # contains a bare-bones HTML file with an iframe proxy
  def iframe
  end

  # A bare page that's "displayed" inside an iframe after a logout has completed
  # Contains a tiny bit of JS that communicates the status back to the iframe parent
  def notify_logout
  end

  private

  def validate_iframe_parent
    @iframe_parent = params[:parent]
    valid_origins = SECRET_SETTINGS[:valid_iframe_origins] || []
    unless valid_origins.any?{|origin| @iframe_parent =~ /^#{origin}/ }
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
  end

end
