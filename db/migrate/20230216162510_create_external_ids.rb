class CreateExternalIds < ActiveRecord::Migration[5.2]
  def up
    create_table :external_ids do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id, null: false, index: { unique: true }

      t.timestamps null: false
    end

    User.reset_column_information
    User.where.not(external_id: nil).find_each do |user|
      ExternalId.new(user: user, external_id: user.external_id).save!
    end

    remove_column :users, :external_id
  end

  def down

  end
end
