class ContactInfosController < ApplicationController

  skip_before_filter :authenticate_user!,
                     only: [:confirm, :confirm_unclaimed, :resend_confirmation]

  skip_before_filter :registration,
                     only: [:create, :destroy, :toggle_is_searchable, :confirm,
                            :confirm_unclaimed, :resend_confirmation]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:create, :destroy, :toggle_is_searchable, :confirm,
                         :confirm_unclaimed, :resend_confirmation]

  before_filter :get_contact_info, only: [:destroy, :toggle_is_searchable]

  def create
    handle_with(ContactInfosCreate,
                success: lambda {
                  redirect_to profile_path(active_tab: :email),
                    notice: (I18n.t :"controllers.contact_infos.verification_sent",
                                    address: @handler_result.outputs[:contact_info].value)},
                failure: lambda { @active_tab = :email; render 'users/edit', status: 400 })
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user,
                                              @contact_info)
    @contact_info.destroy
    redirect_to profile_path(active_tab: :email),
                notice: (I18n.t :"controllers.contact_infos.contact_info_deleted",
                                contact_info: (I18n.t @contact_info.type, scope: :"controllers.contact_infos.types"))
  end

  def toggle_is_searchable
    OSU::AccessPolicy.require_action_allowed!(:toggle_is_searchable,
                                              current_user, @contact_info)
    @contact_info.update_attribute(:is_searchable,
                                   !@contact_info.is_searchable)

    redirect_to profile_path(active_tab: :email),
                notice: (I18n.t :"controllers.contact_infos.search_settings_updated")
  end

  def resend_confirmation
    handle_with(ContactInfosResendConfirmation,
                complete: lambda {
                  contact_info = @handler_result.outputs[:contact_info]

                  msg = contact_info.verified ?
                        (I18n.t :"controllers.contact_infos.already_verified") :
                        (I18n.t :"controllers.contact_infos.verification_sent", address: contact_info.value)

                  redirect_to :back,
                              notice: msg
                })
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
                  render :confirm, status: @handler_result.errors.any? ? 400 : 200
                })
  end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end

end
