class AddRenewalEligibleToUser < ActiveRecord::Migration[5.2]
  def change
    add_column(:users, :renewal_eligible, :boolean)
  end
end
