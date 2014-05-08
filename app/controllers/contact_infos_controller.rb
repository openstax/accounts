class ContactInfosController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:confirm]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:confirm]

  def confirm
    handle_with(ContactInfosConfirm,
                complete: lambda {
                  render :confirm, status: @handler_result.errors.any? ? 400 : 200
                })
  end

end
