# frozen_string_literal: true

class ChangeNewflowSocialToFacebookGoogle < ActiveRecord::Migration[5.2]
  def up
    # we have a mix of legacy and 'newflow' providers in the database
    # this cleans them up to match the new oauth provider names
    Authentication
      .where(provider: 'googlenewflow')
      .update_all( # rubocop:disable Rails/SkipsModelValidations
        provider: 'google_oath2'
      )

    Authentication
      .where(provider: 'facebooknewflow')
      .update_all( # rubocop:disable Rails/SkipsModelValidations
        provider: 'facebook'
      )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
