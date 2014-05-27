class ApplicationController < ActionController::Base
  include Lev::HandleWith

  respond_to :html

  before_filter :authenticate_user!

  layout 'application_body_only'
end