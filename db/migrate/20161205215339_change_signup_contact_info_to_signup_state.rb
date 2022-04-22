class ChangeSignupContactInfoToSignupState < ActiveRecord::Migration[4.2]
  class SignupState < ApplicationRecord
  end

  def up
    rename_table :signup_contact_infos, :signup_states

    SignupState.delete_all

    add_column :signup_states, :role, :string
    change_column :signup_states, :role, :string, null: false
    add_column :signup_states, :return_to, :text

    rename_column :signup_states, :kind, :contact_info_kind
    rename_column :signup_states, :value, :contact_info_value
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
