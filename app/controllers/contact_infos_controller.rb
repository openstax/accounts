class ContactInfosController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:confirm_email]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:confirm_email]

  def confirm_email
    handle_with(EmailConfirm,
                complete: lambda {
                  render :confirm_email, status: @handler_result.errors.any? ? 400 : 200
                })
  end

end
