class RemoveVisibilityAndCacheColumnsFromGroups < ActiveRecord::Migration[6.1]
  def change
    remove_column :groups, :is_public, :boolean, default: false, null: false
    remove_column :groups, :cached_subtree_group_ids, :text
    remove_column :groups, :cached_supertree_group_ids, :text
  end
end
