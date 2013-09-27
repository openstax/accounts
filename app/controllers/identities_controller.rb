class IdentitiesController < ApplicationController

  def new
    @errors ||= env['errors']
    redirect_to root_path, alert: "You are already signed in!" if signed_in?
  end

end