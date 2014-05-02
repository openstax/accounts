class Api::V1::ContactInfosController < OpenStax::Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a piece of contact information.'
    description <<-EOS
      All actions in this controller require that the ContactInfo in
      question belong to the current user, who is determined from the
      Oauth token.

      ContactInfos belong to users.
      They represent email addresses, phone numbers, etc.

      ContactInfos contain 2 String fields: type and value.

      Type specifies the kind of contact info, e.g. 'EmailAddress'.
      Value is the actual contact information, e.g. 'user@example.com'

      ContactInfos also contain a boolean field: verified.
      This field records whether or not this piece of contact info
      has been verified, e.g. by sending a verification email.
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/contact_infos/:id', 'Gets the specified ContactInfo.'
  description <<-EOS
    Shows the specified ContactInfo.

    #{json_schema(Api::V1::ContactInfoRepresenter, include: :readable)}
  EOS
  def show
    standard_read(ContactInfo, params[:id])
  end

  ###############################################################
  # create
  ###############################################################

  api :POST, '/contact_infos/', 'Creates a new unverifed ContactInfo.'
  description <<-EOS
    Creates a new unverified ContactInfo for the current user.
    The verification process will be started when this call
    successfully completes.

    #{json_schema(Api::V1::ContactInfoRepresenter, include: [:writeable])}
  EOS
  def create
    standard_nested_create(ContactInfo, :user, current_user.human_user.id)
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/contact_infos/:id', 'Deletes the specified ContactInfo.'
  description <<-EOS
    Deletes the specified ContactInfo.
  EOS
  def destroy
    standard_destroy(ContactInfo, params[:id])
  end

  ###############################################################
  # resend_confirmation
  ###############################################################

  api :PUT, '/contact_infos/:id/resend_confirmation', 'Restarts the contact info confirmation process.'
  description <<-EOS
    Restarts the confirmation process for the specified ContactInfo.
  EOS
  def resend_confirmation
    contact_info = ContactInfo.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:resend_confirmation, current_user, contact_info)
    SendContactInfoConfirmation.call(contact_info)
    head :no_content
  end

end
