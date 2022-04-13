class Api::V1::ContactInfosController < Api::V1::ApiController

  before_action :get_contact_info

  resource_description do
    api_versions "v1"
    short_description "Represents a user's contact info (email)"
    description <<-EOS
    EOS
  end

  protected

  def get_contact_info
    @contact_info = ContactInfo.find(params[:id])
  end

end
