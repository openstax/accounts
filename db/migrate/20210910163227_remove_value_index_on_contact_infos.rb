class RemoveValueIndexOnContactInfos < ActiveRecord::Migration[5.2]
  def change
    remove_index :contact_infos, name: "index_contact_infos_on_value"
  end
end
