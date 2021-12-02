class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:api, :copyright, :home]

  skip_before_action :complete_signup_profile, only: [:api, :copyright]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:api, :copyright]

  layout 'application'

  def api
  end

  def copyright
  end

  def home
    flash.keep # keep notices and errors through to the redirects below

    if Settings::FeatureFlags.any_newflow_feature_flags?
      signed_in? ? redirect_to(profile_newflow_path) : newflow_authenticate_user!
    else
      signed_in? ? redirect_to(profile_path) : authenticate_user!
    end
  end
end
