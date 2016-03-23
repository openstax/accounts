class ContactInfosController < ApplicationController

  skip_before_filter :authenticate_user!,
                     only: [:confirm, :confirm_unclaimed, :resend_confirmation]

  skip_before_filter :finish_sign_up,
                     only: [:confirm_unclaimed] # TODO still need this skip?

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:create, :destroy, :set_searchable, :confirm,
                         :confirm_unclaimed, :resend_confirmation]

  before_filter :get_contact_info, only: [:destroy, :set_searchable]

  def create
    handle_with(ContactInfosCreate,
                success: lambda {
                  contact_info = @handler_result.outputs.contact_info
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
                },
                failure: lambda {
                  render json: @handler_result.errors.first.translate, status: :unprocessable_entity
                })
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user,
                                              @contact_info)
    @contact_info.destroy
    head :ok
  end

  def set_searchable
    OSU::AccessPolicy.require_action_allowed!(:set_searchable,
                                              current_user, @contact_info)
    @contact_info.update_attribute(:is_searchable, params[:is_searchable])

    render json: {is_searchable: @contact_info.is_searchable}, status: :ok
  end

  def resend_confirmation
    handle_with(ContactInfosResendConfirmation,
                complete: lambda {
                  contact_info = @handler_result.outputs[:contact_info]

                  msg = contact_info.verified ?
                        'Your email address is already verified' :
                        "A verification message has been sent to \"#{contact_info.value}\""

                      render json: {message: msg, is_verified: contact_info.verified}, status: :ok
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
