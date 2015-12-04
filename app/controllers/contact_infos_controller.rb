class ContactInfosController < ApplicationController

  skip_before_filter :authenticate_user!, :registration, only: [:confirm, :confirm_unclaimed,
                                                                :resend_confirmation]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:confirm, :confirm_unclaimed,
                                                                 :resend_confirmation]

  before_filter :get_contact_info, only: [:destroy, :toggle_is_searchable]

  def create
    handle_with(ContactInfosCreate,
                success: lambda {
                  redirect_to profile_path(active_tab: :email),
                    notice: "A verification message has been sent to \"#{
                              @handler_result.outputs[:contact_info].value}\"" },
                failure: lambda { @active_tab = :email; render 'users/edit', status: 400 })
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user,
                                              @contact_info)
    @contact_info.destroy
    redirect_to profile_path(active_tab: :email),
                notice: "#{@contact_info.type.underscore.humanize} deleted"
  end

  def toggle_is_searchable
    OSU::AccessPolicy.require_action_allowed!(:toggle_is_searchable,
                                              current_user, @contact_info)
    @contact_info.update_attribute(:is_searchable,
                                   !@contact_info.is_searchable)

    redirect_to profile_path(active_tab: :email),
                notice: "Search settings updated"
  end

  def resend_confirmation
    handle_with(ContactInfosResendConfirmation,
                complete: lambda {
                  redirect_to :back,
                    notice: "A verification message has been sent to \"#{
                              @handler_result.outputs[:contact_info].value}\"" })
  end


  def confirm_unclaimed
    handle_with(ConfirmUnclaimedAccount,
                complete: lambda {
                  render :confirm_unclaimed, status: @handler_result.errors.any? ? 400 : 200
                })
  end

  def confirm
    handle_with(ContactInfosConfirm,
                complete: lambda {
                  user = @handler_result.outputs.contact_info.try(:user)
                  if @handler_result.errors.any?
                    render :confirm, status: 400
                  elsif user.try(:is_temp?) && user.try(:registration_redirect_url).present?
                    redirect_to user.registration_redirect_url,
                                notice: 'Thanks for adding your email address.'
                  else
                    render :confirm, status: 200
                  end
                })
  end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end

end
