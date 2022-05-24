# TODO: Reenable after fixing name update
# require 'rails_helper'
#
# feature 'User updates profile', js: true do
#   before(:each) do
#     mock_current_user(create_user('user@example.com'))
#     visit '/profile'
#   end
#
#   describe 'Updating name' do
#     before(:each) do
#       find('#name').click
#     end
#
#     scenario 'first name' do
#       fill_in 'first_name', with: 'testuser'
#       find('.glyphicon-ok').click
#       expect(page).to have_link('testuser')
#     end
#
#     scenario 'blank first name' do
#       fill_in 'first_name', with: ''
#       find('.glyphicon-ok').click
#       expect(find('.editable-error-block').text).to include (I18n.t :'javascript.name.first_name_blank')
#     end
#
#     scenario 'blank last name' do
#       fill_in 'last_name', with: ''
#       find('.glyphicon-ok').click
#       expect(find('.editable-error-block').text).to include (I18n.t :'javascript.name.last_name_blank')
#     end
#
#     scenario 'blank first and last name' do
#       fill_in 'first_name', with: ''
#       fill_in 'last_name', with: ''
#       find('.glyphicon-ok').click
#       expect(find('.editable-error-block').text).to include (I18n.t :'javascript.name.first_last_name_blank')
#     end
#
#     scenario 'name with spaces' do
#       fill_in 'last_name', with: '  '
#       find('.glyphicon-ok').click
#       expect(find('.editable-error-block').text).to include (I18n.t :'javascript.name.last_name_blank')
#     end
#
#   end
# end
