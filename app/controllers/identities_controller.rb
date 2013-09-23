class IdentitiesController < ApplicationController

  def new
    @errors ||= env['errors']
  end

end