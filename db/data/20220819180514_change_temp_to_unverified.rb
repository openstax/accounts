# frozen_string_literal: true

# There are no TEMP states on production but this will make sure there are none on other environments

class ChangeTempToUnverified < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    User.where(state: 'temp').each do |user|
      user.state = 'unverified'
      user.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
