# Usage:
#   `expect(response.body_as_hash).to match(user_matcher(blah))`
def user_matcher(user, include_private_data: false)
  base_hash = {
    id: user.id,
    username: user.username,
    name: user.name,
    first_name: user.first_name,
    last_name: user.last_name,
    full_name: user.full_name,
    title: user.title,
    suffix: user.suffix,
    uuid: user.uuid,
    support_identifier: user.support_identifier,
    consent_preferences: user.consent_preferences,
    is_test: user.is_test?,
    is_administrator: user.is_administrator?,
    salesforce_contact_id: user.salesforce_contact_id,
    applications: a_collection_containing_exactly(
      *user.application_users.map do |app_user|
        {
          id: app_user.application_id,
          name: app_user.application.name,
          roles: app_user.roles
        }
      end
    ),
    faculty_status: user.faculty_status.to_s
  }

  if include_private_data
    base_hash[:self_reported_role] = user.role.to_s
    base_hash[:school_name] = user.school.name.to_s
    base_hash[:school_type] = user.school_type.to_s
    base_hash[:school_location] = user.school_location.to_s
    base_hash[:using_openstax] = user.using_openstax
    base_hash[:opt_out_of_cookies] = user.opt_out_of_cookies
    base_hash[:contact_infos] =
      user.contact_infos.none? ?
        [] :  # for some reason `a_collection_containing_exactly` doesn't always work when no elements
        a_collection_containing_exactly(
          *user.contact_infos.order(:id).map do |ci|
            Api::V1::ContactInfoRepresenter.new(ci).to_hash.symbolize_keys
          end
        )
    base_hash[:signed_contract_names] = FinePrint::Contract.published.latest.signed_by(user).pluck(:name)
    base_hash[:external_ids] = a_collection_containing_exactly(*user.external_ids.map(&:external_id))
  end

  base_hash.delete_if { |k,v| v.nil? }

  base_hash
end
