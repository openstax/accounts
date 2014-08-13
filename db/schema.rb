# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140811202025) do

  create_table "application_groups", :force => true do |t|
    t.integer  "application_id",                :null => false
    t.integer  "group_id",                      :null => false
    t.integer  "unread_updates", :default => 1, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "application_groups", ["application_id", "unread_updates"], :name => "index_application_groups_on_application_id_and_unread_updates"
  add_index "application_groups", ["group_id", "application_id"], :name => "index_application_groups_on_group_id_and_application_id", :unique => true
  add_index "application_groups", ["group_id", "unread_updates"], :name => "index_application_groups_on_group_id_and_unread_updates"

  create_table "application_users", :force => true do |t|
    t.integer  "application_id",                         :null => false
    t.integer  "user_id",                                :null => false
    t.integer  "default_contact_info_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "unread_updates",          :default => 1, :null => false
  end

  add_index "application_users", ["application_id", "unread_updates"], :name => "index_application_users_on_application_id_and_unread_updates"
  add_index "application_users", ["application_id"], :name => "index_application_users_on_application_id"
  add_index "application_users", ["default_contact_info_id"], :name => "index_application_users_on_default_contact_info_id"
  add_index "application_users", ["user_id", "application_id"], :name => "index_application_users_on_user_id_and_application_id", :unique => true
  add_index "application_users", ["user_id", "unread_updates"], :name => "index_application_users_on_user_id_and_unread_updates"

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "authentications", ["user_id", "provider"], :name => "index_authentications_on_user_id_scoped", :unique => true

  create_table "contact_infos", :force => true do |t|
    t.string   "type"
    t.string   "value"
    t.boolean  "verified",             :default => false
    t.string   "confirmation_code"
    t.integer  "user_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.datetime "confirmation_sent_at"
  end

  add_index "contact_infos", ["confirmation_code"], :name => "index_contact_infos_on_confirmation_code", :unique => true
  add_index "contact_infos", ["user_id"], :name => "index_contact_infos_on_user_id"
  add_index "contact_infos", ["value", "user_id", "type"], :name => "index_contact_infos_on_value_user_id_type", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "fine_print_contracts", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "version"
    t.string   "title",      :null => false
    t.text     "content",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "fine_print_contracts", ["name", "version"], :name => "index_fine_print_contracts_on_name_and_version", :unique => true

  create_table "fine_print_signatures", :force => true do |t|
    t.integer  "contract_id", :null => false
    t.integer  "user_id",     :null => false
    t.string   "user_type",   :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "fine_print_signatures", ["contract_id"], :name => "index_fine_print_signatures_on_contract_id"
  add_index "fine_print_signatures", ["user_id", "user_type", "contract_id"], :name => "index_fine_print_s_on_u_id_and_u_type_and_c_id", :unique => true

  create_table "group_members", :force => true do |t|
    t.integer  "group_id",   :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "group_members", ["group_id", "user_id"], :name => "index_group_members_on_group_id_and_user_id", :unique => true
  add_index "group_members", ["user_id"], :name => "index_group_members_on_user_id"

  create_table "group_nestings", :force => true do |t|
    t.integer  "member_group_id",    :null => false
    t.integer  "container_group_id", :null => false
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "group_nestings", ["container_group_id"], :name => "index_group_nestings_on_container_group_id"
  add_index "group_nestings", ["member_group_id"], :name => "index_group_nestings_on_member_group_id", :unique => true

  create_table "group_owners", :force => true do |t|
    t.integer  "group_id",   :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "group_owners", ["group_id", "user_id"], :name => "index_group_owners_on_group_id_and_user_id", :unique => true
  add_index "group_owners", ["user_id"], :name => "index_group_owners_on_user_id"

  create_table "groups", :force => true do |t|
    t.boolean  "is_public",                  :default => false, :null => false
    t.string   "name"
    t.text     "cached_subtree_group_ids"
    t.text     "cached_supertree_group_ids"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  add_index "groups", ["is_public"], :name => "index_groups_on_is_public"

  create_table "identities", :force => true do |t|
    t.string   "password_digest"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "user_id",               :null => false
    t.string   "reset_code"
    t.datetime "reset_code_expires_at"
    t.datetime "password_expires_at"
  end

  add_index "identities", ["user_id"], :name => "index_identities_on_user_id"

  create_table "message_bodies", :force => true do |t|
    t.integer  "message_id",                 :null => false
    t.text     "html",       :default => "", :null => false
    t.text     "text",       :default => "", :null => false
    t.string   "short_text", :default => "", :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "message_bodies", ["message_id"], :name => "index_message_bodies_on_message_id", :unique => true

  create_table "message_recipients", :force => true do |t|
    t.integer  "message_id",                         :null => false
    t.integer  "contact_info_id"
    t.integer  "user_id"
    t.string   "recipient_type",                     :null => false
    t.boolean  "read",            :default => false, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "message_recipients", ["contact_info_id", "message_id"], :name => "index_message_recipients_on_contact_info_id_and_message_id", :unique => true
  add_index "message_recipients", ["message_id", "user_id"], :name => "index_message_recipients_on_message_id_and_user_id", :unique => true
  add_index "message_recipients", ["user_id", "read"], :name => "index_message_recipients_on_user_id_and_read"

  create_table "messages", :force => true do |t|
    t.integer  "application_id",                         :null => false
    t.integer  "user_id"
    t.boolean  "send_externally_now", :default => false, :null => false
    t.text     "subject",                                :null => false
    t.string   "subject_prefix",      :default => "",    :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "messages", ["application_id", "user_id"], :name => "index_messages_on_application_id_and_user_id"
  add_index "messages", ["user_id"], :name => "index_messages_on_user_id"

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.string   "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",                                    :null => false
    t.string   "uid",                                     :null => false
    t.string   "secret",                                  :null => false
    t.string   "redirect_uri",                            :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.boolean  "trusted",              :default => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "email_from_address",   :default => "",    :null => false
    t.string   "email_subject_prefix", :default => "",    :null => false
  end

  add_index "oauth_applications", ["owner_id", "owner_type"], :name => "index_oauth_applications_on_owner_id_and_owner_type"
  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "people", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "username",         :default => "",    :null => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.boolean  "is_administrator", :default => false
    t.integer  "person_id"
    t.boolean  "is_temp",          :default => true
    t.string   "first_name"
    t.string   "last_name"
    t.string   "full_name"
    t.string   "title"
    t.string   "uuid"
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true
  add_index "users", ["uuid"], :name => "index_users_on_uuid", :unique => true

end
