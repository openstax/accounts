class ContactParser
	LOG_PATH = "#{Rails.root}/log/#{Rails.env}_salesforce.log"

	def initialize(event)
		@event = event
	end

	def save_contact
		contact_params = sanitize_contact
		ci_table = ContactInfo.arel_table

		contact = User.joins(:contact_infos).eager_load(:contact_infos).where(salesforce_contact_id: nil).where(ci_table[:value].lower.eq(contact_params[:email])).first
		puts(contact_params.inspect)

		if contact.present?
			contact.salesforce_contact_id = contact_params[:sf_id]
			contact.save
			Logger.new(LOG_PATH).info('Contact saved ID: ' + contact.salesforce_contact_id)
		else
			Logger.new(LOG_PATH).info("No contact found for email #{contact_params[:email]}")
		end

	end

	private

	def sanitize_contact
		sobject = @event['sobject']
		{
			email: sobject['Email'],
			sf_id: sobject['Id'],
		}
	end
end
