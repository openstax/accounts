class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!

  skip_before_action :complete_signup_profile, only: [:api, :copyright]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:api, :copyright]

  def api
  end

  def copyright
  end

end
