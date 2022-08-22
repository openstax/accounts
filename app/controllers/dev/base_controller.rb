module Dev
  class BaseController < ApplicationController

    skip_before_action :authenticate_user!

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action Proc.new{
      raise SecurityTransgression if Rails.env.production?
    }

  end
end
