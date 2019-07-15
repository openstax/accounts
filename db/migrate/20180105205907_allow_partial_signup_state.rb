class AllowPartialSignupState < ActiveRecord::Migration[4.2]
  def change
    change_column_null :signup_states, :contact_info_value, true
    change_column_null :signup_states, :contact_info_kind, true

    add_column :signup_states, :is_partial_info_allowed, :boolean, default: false, null: false
  end
end
