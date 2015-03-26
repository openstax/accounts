module Dev
  class BaseController < ApplicationController

    skip_before_filter :authenticate_user!, :require_registration!

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_filter Proc.new{ 
      raise SecurityTransgression if Rails.env.production?
    }
    
  end
end
