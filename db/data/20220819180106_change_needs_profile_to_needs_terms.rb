# frozen_string_literal: true

# As of this migration, current user state counts on production are (excluding activated):
# 20,370 needs_profile -> needs_terms (this migration)
# 3,530 new_social
# 67 unclaimed
# 22,496 unverified

class ChangeNeedsProfileToNeedsTerms < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    User.where(state: 'needs_profile').each do |user|
      user.state = 'needs_terms'
      user.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
