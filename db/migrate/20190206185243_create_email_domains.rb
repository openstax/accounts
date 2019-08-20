class CreateEmailDomains < ActiveRecord::Migration[4.2]
  def change
    create_table :email_domains do |t|
      t.string :value, default: ''
      t.boolean :has_mx, default: false

      t.timestamps null: false
    end
  end
end
