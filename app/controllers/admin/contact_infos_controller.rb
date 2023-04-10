module Admin
  class ContactInfosController < Admin::BaseController

    def verify
      contact_info = ContactInfo.find(params[:id])
      result = MarkContactInfoVerified.call(contact_info)
      if result.errors.any?
        return render plain: '(Unable to confirm)'
      else
        security_log :contact_info_confirmed_by_admin, contact_info_id: params[:id]
        return render plain: '(Confirmed)'
      end
    end

    def destroy
      contact_info = ContactInfo.find(params[:id])
      contact_info.delete
      redirect_to edit_admin_user_path(contact_info.user)
    end
  end
end
