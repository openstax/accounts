require 'rails_helper'

describe ConfirmContactInfo do
  let!(:living_user) { FactoryBot.create :user }
  let!(:contact_info) do
    AddEmailToUser.call('shared@example.com', living_user, already_verified: false)
    living_user.contact_infos.first
  end

  it 'marks the contact info verified' do
    ConfirmContactInfo.call(contact_info)
    expect(contact_info.reload.verified).to be_truthy
  end

  context 'when an unclaimed user shares the same email' do
    let!(:unclaimed_user) do
      u = FactoryBot.create :user, state: 'unclaimed'
      AddEmailToUser.call('other@example.com', u)
      u
    end

    it 'merges the unclaimed user into the confirming user and destroys it' do
      group = FactoryBot.create(:group)
      group.add_member unclaimed_user

      # Force a duplicate email value onto the unclaimed user, bypassing validation, to
      # simulate historically-created duplicate data (this is exactly what
      # MergeUnclaimedUsers exists to clean up).
      dup_email = unclaimed_user.contact_infos.first
      dup_email.value = 'shared@example.com'
      dup_email.save(validate: false)

      expect do
        ConfirmContactInfo.call(contact_info)
      end.to change(User, :count).by(-1)

      expect { unclaimed_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(living_user.reload.member_groups).to include(group)
      expect(contact_info.reload.verified).to be_truthy
    end
  end
end
