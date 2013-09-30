class IdentitiesController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:new]

  def new
    @errors ||= env['errors']

    if !current_user.is_anonymous? && current_user.authentications.any?{|auth| auth.provider == 'identity'}
      redirect_to root_path, alert: "You are already have a simple username and password on your account!"
    end
  end

end