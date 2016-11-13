class AddLoginHintToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :login_hint, :string
  end
end
