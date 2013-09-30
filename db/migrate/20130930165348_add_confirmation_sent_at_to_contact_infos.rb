class AddConfirmationSentAtToContactInfos < ActiveRecord::Migration
  def change
    add_column :contact_infos, :confirmation_sent_at, :datetime
  end
end
