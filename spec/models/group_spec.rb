# require 'rails_helper'
#
# describe Group, type: :model do
#
#   let!(:user_1) { FactoryBot.create(:user) }
#   let!(:user_2) { FactoryBot.create(:user) }
#
#   let!(:group_1) { FactoryBot.create(:group) }
#   let!(:group_2) { FactoryBot.create(:group) }
#
#   context 'validation' do
#     it 'must have a unique name, if present' do
#       group_1.name = nil
#       group_1.save!
#       group_1.name = 'MyGroup'
#       group_1.save!
#
#       group_3 = FactoryBot.build(:group, name: group_1.name)
#       expect(group_3).not_to be_valid
#       expect(group_3).to have_error(:name, :taken)
#
#       group_3.name = nil
#       expect(group_3).to be_valid
#     end
#   end
#
#   it 'can have members added' do
#     expect(group_1.has_member?(user_1)).to eq(false)
#
#     group_1.add_member(user_1)
#     group_1.save!
#     group_1.reload
#
#     expect(group_1.has_member?(user_1)).to eq(true)
#     expect(group_1.has_member?(user_2)).to eq(false)
#
#     group_1.add_member(user_2)
#     group_1.reload
#
#     expect(group_1.has_member?(user_2)).to eq(true)
#   end
#
#   it 'can find members in nested groups' do
#     group_2.add_member(user_2)
#     expect(group_1.has_member?(user_1)).to eq(false)
#     expect(group_1.has_member?(user_2)).to eq(false)
#     expect(group_2.has_member?(user_2)).to eq(true)
#
#     FactoryBot.create(:group_nesting, container_group: group_1, member_group: group_2)
#     group_1.reload
#
#     expect(group_1.has_member?(user_1)).to eq(false)
#     expect(group_1.has_member?(user_2)).to eq(true)
#
#     group_2.add_member(user_1)
#     group_2.reload
#
#     expect(group_2.has_member?(user_1)).to eq(true)
#
#     group_1.reload
#     expect(group_1.has_member?(user_1)).to eq(true)
#   end
#
# end
