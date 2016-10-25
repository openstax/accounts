class ApplicationController < ActionController::Base

  include Lev::HandleWith

  respond_to :html

end
