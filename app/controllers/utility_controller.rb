class UtilityController < ApplicationController

  skip_protect_beta :only => [:status]

  # Used by AWS (and others) to make sure the site is still up.
  def status
    head :ok
  end

end