class AddLoginHintToAuthentications < ActiveRecord::Migration[4.2]
  def change
    add_column :authentications, :login_hint, :string
  end
end
