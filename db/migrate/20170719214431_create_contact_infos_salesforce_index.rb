class CreateContactInfosSalesforceIndex < ActiveRecord::Migration
  def change
    add_index :contact_infos,
              [:value, :verified],
              name: "index_contact_infos_on_value_and_verified_case_insensitive",
              case_sensitive: false
  end
end
