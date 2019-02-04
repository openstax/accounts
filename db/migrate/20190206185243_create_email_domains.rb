class CreateEmailDomains < ActiveRecord::Migration
  def change
    create_table :email_domains do |t|
      t.string :value, default: ''
      t.boolean :has_mx, default: false

      t.timestamps null: false
    end
  end
end
