class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:iframe, :notify_logout]
  skip_before_filter :finish_sign_up,     only: [:iframe]
  skip_before_filter :expired_password,   only: [:iframe]
  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:iframe]

  before_filter :require_parent_param, only: [:iframe, :notify_logout]
  before_filter :allow_iframe_access, only: [:iframe, :notify_logout]

  layout false

  # contains a bare-bones HTML file with an iframe proxy
  def iframe
    store_url
  end

  # A bare page that's "displayed" inside an iframe after a logout has completed
  # Contains a tiny bit of JS that communicates the status back to the iframe parent
  def notify_logout
  end

  protected

  def require_parent_param
    if @iframe_parent.blank?
      raise SecurityTransgression.new("must supply valid 'parent' query parameter")
    end
  end

end
