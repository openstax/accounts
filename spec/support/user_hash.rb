# user_hash is the old way of checking user controller responses; it can fail
# on out of order contact_infos and also doesn't clear failure output since
# it is normally a global string comparison.
#
#   expect(response.body).to eq(user_hash(blah).to_json)
#
# user_matcher is the newer way to go.
#
#   expect(response.body_as_hash).to match(user_matcher(blah))

def user_hash(user, include_private_data: false)
  base_hash = {
    'id' => user.id,
    'username' => user.username,
    'first_name' => user.first_name,
    'last_name' => user.last_name,
    'full_name' => user.full_name,
    'uuid' => user.uuid,
    'applications' => user.applications.order(:id).map{|app| {"id" => app.id, "name" => app.name}}
  }

  if include_private_data
    base_hash['salesforce_contact_id'] = user.salesforce_contact_id
    base_hash['faculty_status'] = user.faculty_status.to_s
    base_hash['self_reported_role'] = user.role.to_s
    base_hash['contact_infos'] = a_collection_including(
      user.contact_infos.order(:id).map{|ci|
        Api::V1::ContactInfoRepresenter.new(ci).to_hash
      }
    )
  end

  base_hash
end


def user_matcher(user, include_private_data: false)
  base_hash = {
    id: user.id,
    username: user.username,
    first_name: user.first_name,
    last_name: user.last_name,
    full_name: user.full_name,
    uuid: user.uuid,
    applications: a_collection_containing_exactly(
      *user.applications.map{|app|
        a_hash_including({id: app.id, name: app.name})
      }
    )
  }

  if include_private_data
    base_hash[:salesforce_contact_id] = user.salesforce_contact_id
    base_hash[:faculty_status] = user.faculty_status.to_s
    base_hash[:self_reported_role] = user.role.to_s
    base_hash[:contact_infos] =
      user.contact_infos.none? ?
        [] :  # for some reason `a_collection_containing_exactly` doesn't always work when no elements
        a_collection_containing_exactly(
          *user.contact_infos.order(:id).map{|ci|
            Api::V1::ContactInfoRepresenter.new(ci).to_hash.symbolize_keys
          }
        )
  end

  base_hash.delete_if{|k,v| v.nil?}

  base_hash
end
