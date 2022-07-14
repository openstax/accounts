class ContactInfosController < ApplicationController

  skip_before_action :authenticate_user!, only: [:confirm, :confirm_unclaimed, :resend_confirmation]
  skip_before_action :complete_signup_profile, only: [:confirm_unclaimed]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:create, :destroy, :set_searchable, :confirm,
                         :confirm_unclaimed, :resend_confirmation]

  before_action :get_contact_info, only: [:destroy, :set_searchable]

  def create
    handle_with(ContactInfosCreate,
                success: lambda do
                  contact_info = @handler_result.outputs.contact_info
                  security_log :contact_info_created, contact_info_id: contact_info.id,
                                                      contact_info_type: contact_info.type,
                                                      contact_info_value: contact_info.value
                  render json: {
                    contact_info: {
                      id: contact_info.id,
                      type: contact_info.type,
                      value: contact_info.value,
                      is_verified: contact_info.verified,
                      is_searchable: contact_info.is_searchable
                    }
                  },
                  status: :ok
                end,
                failure: lambda do
                  render json: @handler_result.errors.first.translate, status: :unprocessable_entity
                end)
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user, @contact_info)
    security_log :contact_info_deleted, contact_info_id: params[:id],
                                        contact_info_type: @contact_info.type,
                                        contact_info_value: @contact_info.value
    @contact_info.destroy
    head :ok
  end

  def set_searchable
    OSU::AccessPolicy.require_action_allowed!(:set_searchable, current_user, @contact_info)
    security_log :contact_info_updated, contact_info_id: params[:id],
                                        contact_info_type: @contact_info.type,
                                        contact_info_value: @contact_info.value,
                                        contact_info_is_searchable: params[:is_searchable]
    @contact_info.update_attribute(:is_searchable, params[:is_searchable])

    render json: {is_searchable: @contact_info.is_searchable}, status: :ok
  end

  def resend_confirmation
    handle_with(ContactInfosResendConfirmation,
                complete: lambda do
                  contact_info = @handler_result.outputs[:contact_info]

                  if contact_info.verified
                    msg = I18n.t :"controllers.contact_infos.already_verified"
                  else
                    msg = I18n.t :"controllers.contact_infos.verification_sent",
                                 address: contact_info.value
                    security_log :contact_info_confirmation_resent,
                                 contact_info_id: contact_info.id,
                                 contact_info_type: contact_info.type,
                                 contact_info_value: contact_info.value
                  end

                  render json: {message: msg, is_verified: contact_info.verified}, status: :ok
                end)
  end

  def confirm_unclaimed
    handle_with(ConfirmUnclaimedAccount,
                user_state: self,
                complete: lambda do
                  contact_info = @handler_result.outputs.contact_info

                  if @handler_result.errors.any?
                    contact_info_event_type = :contact_info_confirmation_by_code_failed
                    head(:bad_request)
                  else
                    contact_info_event_type = :contact_info_confirmed_by_code
                    sign_in!(contact_info.user)

                    app = contact_info.user.applications.first
                    # an app should always be present but there may be legacy invites that lack it
                    if app

                      # store the url of the app so they will be redirected
                      # to it once the password reset and terms screens are finished
                      store_url(
                        url: oauth_authorization_url(
                          client_id: app.uid,
                          redirect_uri: app.redirect_uri.lines.last.chomp,
                          response_type: 'code'
                        )
                      )
                    end
                    render :confirm_unclaimed

                    security_log :user_claimed, user_id: contact_info.user.id
                  end
                  security_log contact_info_event_type, contact_info_id: contact_info.try(:id),
                                                        contact_info_type: contact_info.try(:type),
                                                        contact_info_value: contact_info.try(:value)
                end)
  end

  def confirm
    handle_with(ContactInfosConfirm,
                complete: lambda do
                  contact_info = @handler_result.outputs.contact_info

                  if @handler_result.errors.any?
                    event_type = :contact_info_confirmation_by_code_failed
                    status = 400
                  else
                    event_type = :contact_info_confirmed_by_code
                    status = 200
                  end

                  security_log event_type, contact_info_id: contact_info.try(:id),
                                           contact_info_type: contact_info.try(:type),
                                           contact_info_value: contact_info.try(:value)
                  render :confirm, status: status
                end)
  end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end

end
