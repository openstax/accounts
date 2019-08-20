class CreateContactInfosSalesforceIndex < ActiveRecord::Migration[5.2]
  change_table :contact_infos do |t|
    t.index 'lower(value), verified',
              name: "index_contact_infos_on_value_and_verified_case_insensitive"
  end
end
