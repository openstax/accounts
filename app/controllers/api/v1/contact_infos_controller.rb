class Api::V1::ContactInfosController < OpenStax::Api::V1::OauthBasedApiController

  doorkeeper_for :all

  resource_description do
    api_versions "v1"
    short_description 'Represents a piece of contact information.'
    description <<-EOS
      ContactInfos include email addresses, phone numbers, etc.  
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/contact_infos/:id', 'Gets the specified ContactInfo'
  description <<-EOS
    #{json_schema(Api::V1::ContactInfoRepresenter, include: :readable)}            
  EOS
  def show
    standard_read(ContactInfo, params[:id])
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/users/:user_id/contact_infos/', 'Creates a new unverifed ContactInfo'
  param :user_id, :number, required: true, desc: <<-EOS
    The ID of the user to which the new ContactInfo should be added.
  EOS
  description <<-EOS
    Lets a caller create a new unverified ContactInfo.  The verification
    process will be started when this call successfully completes.

    #{json_schema(Api::V1::ContactInfoRepresenter, include: [:writeable])}            
  EOS
  def create
    standard_nested_create(ContactInfo, :user, params[:user_id])
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/contact_infos/:id', 'Deletes the specified ContactInfo'
  description <<-EOS
    Deletes the specified ContactInfo
  EOS
  def destroy
    standard_destroy(ContactInfo, params[:id])
  end

  api :PUT, '/contact_infos/:id/resend_confirmation', 'Restart the contact info confirmation process'
  def resend_confirmation
    contact_info = ContactInfo.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:resend_confirmation, current_user, contact_info)
    SendContactInfoConfirmation.call(contact_info)
    head :no_content
  end

end