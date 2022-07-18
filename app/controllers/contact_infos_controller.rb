class ContactInfosController < ApplicationController

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:create, :destroy, :set_searchable, :confirm,
                         :confirm_unclaimed, :resend_confirmation]

  before_action :get_contact_info, only: [:destroy, :set_searchable]

  def create
    handle_with(CreateEmailForUser,
      success: lambda {
        email = @handler_result.outputs.email
        contact_info = @handler_result.outputs.contact_info
        security_log :email_added_to_user, contact_info_id: contact_info.id,
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
      },
      failure: lambda {
        render json: @handler_result.errors.first.translate, status: :unprocessable_entity
      }
    )
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

  def confirm
    handle_with(ConfirmByCode,
              complete: lambda do
                contact_info = @handler_result.outputs.contact_info
                if @handler_result.errors.any?
                  event_type = :contact_info_confirmation_by_code_failed
                  status     = 400
                else
                  event_type = :contact_info_confirmed_by_code
                  status     = 200
                end
                security_log event_type, contact_info_id: contact_info.try(:id),
                             contact_info_type:           contact_info.try(:type),
                             contact_info_value:          contact_info.try(:value)
                render :confirm, status: status
              end)
end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end
end
