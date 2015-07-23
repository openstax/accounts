module Admin
  class ContactInfosController < BaseController

    def verify
      contact_info = ContactInfo.find(params[:id])
      result = MarkContactInfoVerified.call(contact_info)
      if result.errors.any?
        return render text: '(Unable to verify)'
      else
        return render text: '(Verified)'
      end
    end

  end
end
