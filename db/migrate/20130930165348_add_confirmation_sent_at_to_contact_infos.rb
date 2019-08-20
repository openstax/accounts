class AddConfirmationSentAtToContactInfos < ActiveRecord::Migration[4.2]
  def change
    add_column :contact_infos, :confirmation_sent_at, :datetime
  end
end
