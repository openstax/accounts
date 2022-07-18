class Api::V1::ContactInfosController < Api::V1::ApiController

  before_action :get_contact_info, only: [:resend_confirmation, :confirm_by_pin]

  resource_description do
    api_versions "v1"
    short_description "Represents a user's contact info (email)"
    description <<-EOS
    EOS
  end

  # api :PUT, '/contact_infos/:id/resend_confirmation',
  #           'Resends the message with instructions on how to confirm the contact info'
  # description <<-EOS
  #   Does not require an input body, but a body can be used to indicate a PIN should
  #   be sent.  Called by users (or code running on behalf of users).
  #
  #   This is always a "resend" because a confirmation message is always sent when a
  #   contact info is added to an account.
  #
  #   Returns:
  #   * 403 if the contact info is not owned by the current user
  #   * 204 if the contact info is owned by the current user and is unconfirmed
  #   * 422 if the contact info is owned by the current user but is already confirmed.
  #     Includes an `already_confirmed` error message.
  #
  #   #{json_schema(Api::V1::ResendConfirmationRepresenter, include: :writeable)}
  # EOS
  # def resend_confirmation
  #   OSU::AccessPolicy.require_action_allowed!(:resend_confirmation, current_api_user, @contact_info)
  #   if @contact_info.confirmed?
  #     render_api_errors(:already_confirmed)
  #   else
  #     security_log :contact_info_confirmation_resent, contact_info_id: params[:id],
  #                                                     contact_info_type: @contact_info.type,
  #                                                     contact_info_value: @contact_info.value
  #
  #     payload = consume!(Hashie::Mash.new, represent_with: Api::V1::ResendConfirmationRepresenter)
  #     SendContactInfoConfirmation.call(contact_info: @contact_info)
  #     head :no_content
  #   end
  # end

  # api :PUT, '/contact_infos/:id/confirm_by_pin', 'Confirm a contact info using a PIN'
  # description <<-EOS
  #   Confirm a contact info using a PIN.  Called by users (or code running on behalf of users).
  #
  #   Returns:
  #   * 403 if the contact info is not owned by the current user
  #   * 204 if:
  #      1. the confirmation is successful (contact info is owned by current user,
  #         is unconfirmed, pin confirmation is allowed, pin matches, and was able to
  #         mark confirmed), OR
  #      2. the contact info is owned by the user and is already confirmed
  #   * 422 if the contact info is owned by the user and is unconfirmed but:
  #      1. pin confirmation is no longer allowed (out of attempts). Includes a
  #         `no_pin_confirmation_attempts_remaining` error message, OR
  #      2. the pin is not correct. Includes a `pin_not_correct` error message.
  #
  #   #{json_schema(Api::V1::ConfirmByPinRepresenter, include: :writeable)}
  # EOS
  # def confirm_by_pin
  #   OSU::AccessPolicy.require_action_allowed!(:confirm_by_pin, current_api_user, @contact_info)
  #
  #   if @contact_info.confirmed?
  #     head :no_content
  #   else
  #     payload = consume!(Hashie::Mash.new, represent_with: Api::V1::ConfirmByPinRepresenter)
  #     outputs = ConfirmByPin.call(contact_info: @contact_info, pin: payload.pin)
  #
  #     if render_api_errors(outputs.errors)
  #       security_log :contact_info_confirmation_by_pin_failed,
  #                    contact_info_id: params[:id],
  #                    contact_info_type: @contact_info.type,
  #                    contact_info_value: @contact_info.value
  #     else
  #       security_log :contact_info_confirmed_by_pin, contact_info_id: params[:id],
  #                                                    contact_info_type: @contact_info.type,
  #                                                    contact_info_value: @contact_info.value
  #       head :no_content
  #     end
  #   end
  # end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end

end
