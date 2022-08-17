class ExternalAppForSpecsController < ApplicationController
  layout false

  skip_before_action :save_redirect # it gets magically added in initializers/controllers.rb
  skip_before_action :authenticate_user!, only: [:public]

  def index
    render plain: 'External application loaded successfully.'
  end

  def public
    render plain: 'External application — public url — loaded successfully.'
  end
end
