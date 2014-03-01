# Copyright 2011-2012 Rice University. Licensed under the Affero General Public 
# License version 3 or later.  See the COPYRIGHT file for details.

module Admin
  class BaseController < ApplicationController
    
    before_filter :authenticate_admin!
    
    def cron
      Ost::Cron::execute_cron_jobs
      flash[:notice] = "Ran cron tasks"
      redirect_to admin_path  
    end

    def raise_security_transgression
      raise SecurityTransgression
    end

    def raise_record_not_found
      raise ActiveRecord::RecordNotFound
    end

    def raise_routing_error
      raise ActionController::RoutingError.new "/blah/blah/blah"
    end

    def raise_unknown_controller
      raise ActionController::UnknownController
    end

    def raise_unknown_action
      raise ActionController::UnknownAction
    end

    def raise_missing_template
      raise ActionView::MissingTemplate.new(['a', 'b'], 'path', ['pre1', 'pre2'], 'partial', 'details')
    end

    def raise_not_yet_implemented
      raise NotYetImplemented
    end

    def raise_illegal_argument
      raise IllegalArgument
    end

  end
end