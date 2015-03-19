class ContactInfosController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:confirm]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:confirm]

  before_filter :get_contact_info, only: [:destroy, :toggle_is_searchable]

  def create
    handle_with(ContactInfosCreate,
                success: lambda {
                  redirect_to profile_path,
                    notice: "A confirmation message has been sent to \"#{
                              @handler_result.outputs[:contact_info].value}\"" },
                failure: lambda { render 'users/edit', status: 400 })
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user,
                                              @contact_info)
    @contact_info.destroy
    redirect_to profile_path,
                notice: "#{@contact_info.type.underscore.humanize} deleted"
  end

  def toggle_is_searchable
    OSU::AccessPolicy.require_action_allowed!(:toggle_is_searchable,
                                              current_user, @contact_info)
    @contact_info.update_attribute(:is_searchable,
                                   !@contact_info.is_searchable)
    redirect_to profile_path,
                notice: "Search settings updated"
  end

  def resend_confirmation
    handle_with(ContactInfosResendConfirmation,
                complete: lambda {
                  redirect_to profile_path,
                    notice: "A confirmation message has been sent to \"#{
                              @handler_result.outputs[:contact_info].value}\"" })
  end

  def confirm
    handle_with(ContactInfosConfirm,
                complete: lambda {
                  render :confirm, status: @handler_result.errors.any? ? 400 : 200
                })
  end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end

end
