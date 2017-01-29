module Admin
  class ContactInfosController < BaseController

    def verify
      contact_info = ContactInfo.find(params[:id])
      result = MarkContactInfoVerified.call(contact_info)
      if result.errors.any?
        return render text: '(Unable to confirm)'
      else
        security_log :contact_info_confirmed_by_admin, contact_info_id: params[:id]
        return render text: '(Confirmed)'
      end
    end

  end
end
