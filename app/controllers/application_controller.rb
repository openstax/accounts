class ApplicationController < ActionController::Base
  include Lev::HandleWith

  respond_to :html

  layout 'application_body_only'
end