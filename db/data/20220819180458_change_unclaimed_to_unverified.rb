# frozen_string_literal: true

# As of this migration, current user state counts on production are (excluding activated):
# 20,370 needs_profile
# 3,530 new_social
# 67 unclaimed -> unclaimed (this migration)
# 22,496 unverified

class ChangeUnclaimedToUnverified < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    User.where(state: 'unclaimed').each do |user|
      user.state = 'unverified'
      user.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
