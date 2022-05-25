# TODO: reimplement when using groups
# require 'rails_helper'
#
# describe Api::V1::GroupMembersController, type: :controller, api: true, version: :v1 do
#
#   let!(:group_1) { FactoryBot.create :group, name: 'Group 1',
#                                       members_count: 0, owners_count: 0 }
#   let!(:group_2) { FactoryBot.create :group, name: 'Group 2',
#                                       members_count: 0, owners_count: 0 }
#   let!(:group_3) { FactoryBot.create :group, name: 'Group 3',
#                                       members_count: 0, owners_count: 0, is_public: true }
#
#   let!(:user_1)       { FactoryBot.create :user, :terms_agreed }
#   let!(:user_2)       { FactoryBot.create :user, :terms_agreed }
#
#   let!(:group_member_1) { FactoryBot.create :group_member, group: group_2, user: user_2 }
#
#   let!(:untrusted_application) { FactoryBot.create :doorkeeper_application }
#
#   let!(:user_1_token) { FactoryBot.create :doorkeeper_access_token,
#                         application: untrusted_application,
#                         resource_owner_id: user_1.id }
#   let!(:user_2_token) { FactoryBot.create :doorkeeper_access_token,
#                         application: untrusted_application,
#                         resource_owner_id: user_2.id }
#   let!(:untrusted_application_token) { FactoryBot.create :doorkeeper_access_token,
#                                        application: untrusted_application,
#                                        resource_owner_id: nil }
#
#   context 'index' do
#     it 'must not list group memberships without a token' do
#       api_get :index, nil
#
#       expect(response).to have_http_status :forbidden
#     end
#
#     it 'must not list group memberships for an app without a user token' do
#       api_get :index, untrusted_application_token
#
#       expect(response).to have_http_status :forbidden
#     end
#
#     it 'must list all group memberships for human users' do
#       api_get :index, user_1_token
#
#       expect(response.code).to eq('200')
#       expected_response = []
#
#       expect(response.body_as_hash).to eq(expected_response)
#
#       group_1.add_member(user_1)
#       controller.current_human_user.reload
#
#       api_get :index, user_1_token
#
#       expect(response.code).to eq('200')
#       expected_response = [
#         {
#           user_id: user_1.id,
#           group: {
#             id: group_1.id,
#             name: 'Group 1',
#             is_public: false,
#             owners: [],
#             members: [
#               {
#                 group_id: group_1.id,
#                 user: user_matcher(user_1)
#               }
#             ],
#             nestings: [],
#             supertree_group_ids: [group_1.id],
#             subtree_group_ids: [group_1.id],
#             subtree_member_ids: [user_1.id]
#           }
#         }
#       ]
#
#       expect(response.body_as_hash).to match(expected_response)
#
#       FactoryBot.create(:group_nesting, container_group: group_1, member_group: group_2)
#       controller.current_human_user.reload
#
#       api_get :index, user_1_token
#
#       expect(response.code).to eq('200')
#
#       group_1.reload
#       group_1_json = {
#         user_id: user_1.id,
#         group: {
#           id: group_1.id,
#           name: 'Group 1',
#           is_public: false,
#           owners: [],
#           members: [
#             {
#               group_id: group_1.id,
#               user: user_matcher(user_1)
#             }
#           ],
#           nestings: [
#             {
#               container_group_id: group_1.id,
#               member_group_id: group_2.id,
#             }
#           ],
#           supertree_group_ids: [group_1.id],
#           subtree_group_ids: group_1.subtree_group_ids,
#           subtree_member_ids: group_1.subtree_member_ids
#         }
#       }
#
#       expected_response = [group_1_json]
#
#       expect(response.body_as_hash).to match(expected_response)
#       expect(group_1.subtree_group_ids).to include(group_1.id)
#       expect(group_1.subtree_group_ids).to include(group_2.id)
#       expect(group_1.subtree_member_ids).to include(user_1.id)
#       expect(group_1.subtree_member_ids).to include(user_2.id)
#
#       group_2.add_member(user_1)
#       controller.current_human_user.reload
#
#       api_get :index, user_1_token
#
#       expect(response.code).to eq('200')
#
#       group_1.reload
#       group_1_json = {
#         user_id: user_1.id,
#         group: {
#           id: group_1.id,
#           name: 'Group 1',
#           is_public: false,
#           owners: [],
#           members: [
#             {
#               group_id: group_1.id,
#               user: user_matcher(user_1)
#             }
#           ],
#           nestings: [
#             {
#               container_group_id: group_1.id,
#               member_group_id: group_2.id,
#             }
#           ],
#           supertree_group_ids: [group_1.id],
#           subtree_group_ids: group_1.subtree_group_ids,
#           subtree_member_ids: group_1.subtree_member_ids
#         }
#       }
#
#       group_2.reload
#       group_2_json = {
#         user_id: user_1.id,
#         group: {
#           id: group_2.id,
#           name: 'Group 2',
#           is_public: false,
#           owners: [],
#           members: a_collection_containing_exactly(
#             *group_2.group_members.map do |group_member|
#               {
#                 group_id: group_2.id,
#                 user: user_matcher(group_member.user)
#               }
#             end
#           ),
#           nestings: [],
#           supertree_group_ids: group_2.supertree_group_ids,
#           subtree_group_ids: [group_2.id],
#           subtree_member_ids: group_2.subtree_member_ids
#         }
#       }
#
#       expect(response.body_as_hash).to include(group_1_json)
#       expect(response.body_as_hash).to include(group_2_json)
#       expect(group_1.subtree_group_ids).to include(group_1.id)
#       expect(group_1.subtree_group_ids).to include(group_2.id)
#       expect(group_1.subtree_member_ids).to include(user_1.id)
#       expect(group_1.subtree_member_ids).to include(user_2.id)
#       expect(group_2.supertree_group_ids).to include(group_1.id)
#       expect(group_2.supertree_group_ids).to include(group_2.id)
#       expect(group_2.subtree_member_ids).to include(user_1.id)
#       expect(group_2.subtree_member_ids).to include(user_2.id)
#       expect(group_2.members).to include(user_1)
#       expect(group_2.members).to include(user_2)
#
#       group_3.add_member(user_1)
#       controller.current_human_user.reload
#
#       api_get :index, user_1_token
#
#       expect(response.code).to eq('200')
#
#       group_3.reload
#       group_3_json = {
#         user_id: user_1.id,
#         group: {
#           id: group_3.id,
#           name: 'Group 3',
#           is_public: true,
#           owners: [],
#           members: [
#             { group_id: group_3.id,
#               user: user_matcher(user_1) }
#           ],
#           nestings: [],
#           supertree_group_ids: [group_3.id],
#           subtree_group_ids: [group_3.id],
#           subtree_member_ids: [user_1.id]
#         }
#       }
#
#       expect(response.body_as_hash).to include(group_1_json)
#       expect(response.body_as_hash).to include(group_2_json)
#       expect(response.body_as_hash).to include(group_3_json)
#     end
#   end
#
#   context 'create' do
#     it 'must not create a group_member without a token' do
#       api_post :create, nil, params: { group_id: group_3.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#     end
#
#     it 'must not create a group_member for an app without a user token' do
#       api_post :create, untrusted_application_token,
#                         params: { group_id: group_3.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#     end
#
#     it 'must not create a group_member for an unauthorized user' do
#       api_post :create, user_1_token, params: { group_id: group_3.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#
#       group_3.add_member(user_1)
#       controller.current_human_user.reload
#
#       api_post :create, user_1_token, params: { group_id: group_3.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#     end
#
#     it 'must create group_members for authorized users' do
#       group_3.add_owner(user_1)
#       api_post :create, user_1_token, params: { group_id: group_3.id, user_id: user_2.id }
#
#       expect(response.code).to eq('201')
#       expected_response = {
#         user_id: user_2.id,
#         group: {
#           id: group_3.id,
#           name: 'Group 3',
#           is_public: true,
#           owners: [
#             {
#               group_id: group_3.id,
#               user: user_matcher(user_1)
#             }
#           ],
#           members: [
#             {
#               group_id: group_3.id,
#               user: user_matcher(user_2)
#             }
#           ],
#           nestings: [],
#           supertree_group_ids: [group_3.id],
#           subtree_group_ids: [group_3.id],
#           subtree_member_ids: [user_2.id]
#         }
#       }
#       expect(response.body_as_hash).to match(expected_response)
#
#       group_1.add_owner(user_1)
#       api_post :create, user_1_token, params: { group_id: group_1.id, user_id: user_1.id }
#
#       expect(response.code).to eq('201')
#       expected_response = {
#         user_id: user_1.id,
#         group: {
#           id: group_1.id,
#           name: 'Group 1',
#           is_public: false,
#           owners: [
#             { group_id: group_1.id,
#               user: user_matcher(user_1)
#             }
#           ],
#           members: [
#             {
#               group_id: group_1.id,
#               user: user_matcher(user_1)
#             }
#           ],
#           nestings: [],
#           supertree_group_ids: [group_1.id],
#           subtree_group_ids: [group_1.id],
#           subtree_member_ids: [user_1.id]
#         }
#       }
#       expect(response.body_as_hash).to match(expected_response)
#     end
#   end
#
#   context 'destroy' do
#     it 'must not destroy a group_member without a token' do
#       api_delete :destroy, nil, params: { group_id: group_2.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#       expect(GroupMember.where(id: group_member_1.id).first).not_to be_nil
#     end
#
#     it 'must not destroy a group_member for an app without a user token' do
#       api_delete :destroy, untrusted_application_token,
#                           params: { group_id: group_2.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#       expect(GroupMember.where(id: group_member_1.id).first).not_to be_nil
#     end
#
#     it 'must not destroy a group_member for an unauthorized user' do
#       api_delete :destroy, user_1_token, params: { group_id: group_2.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#       expect(GroupMember.where(id: group_member_1.id).first).not_to be_nil
#
#       group_2.add_member(user_1)
#
#       api_delete :destroy, user_1_token, params: { group_id: group_2.id, user_id: user_2.id }
#
#       expect(response).to have_http_status :forbidden
#       expect(GroupMember.where(id: group_member_1.id).first).not_to be_nil
#     end
#
#     it 'must destroy group_members for authorized users' do
#       group_2.add_member(user_1)
#       group_member_2 = GroupMember.last
#       api_delete :destroy, user_1_token, params: { group_id: group_2.id, user_id: user_1.id }
#
#       expect(response.code).to eq('204')
#       expect(response.body).to be_blank
#       expect(GroupMember.where(id: group_member_2.id).first).to be_nil
#
#       group_2.add_owner(user_1)
#       api_delete :destroy, user_1_token, params: { group_id: group_2.id, user_id: user_2.id }
#
#       expect(response.code).to eq('204')
#       expect(response.body).to be_blank
#       expect(GroupMember.where(id: group_member_1.id).first).to be_nil
#     end
#   end
#
#
# end
