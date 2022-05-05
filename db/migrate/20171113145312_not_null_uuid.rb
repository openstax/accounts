class NotNullUuid < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'pgcrypto'

    User.where(uuid: nil)
        .update_all('"uuid" = gen_random_uuid()') # rubocop:disable Rails/SkipsModelValidations

    change_column(
      :users, :uuid, :uuid,
      using: 'uuid::uuid',
      default: 'gen_random_uuid()',
      null: false
    )

  end
end
