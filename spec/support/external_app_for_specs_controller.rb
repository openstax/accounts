class ExternalAppForSpecsController < ApplicationController
  layout false

  skip_before_action :save_redirect # it gets magically added in initializers/controllers.rb

  def index
    render plain: 'External application loaded successfully.'
  end
end
