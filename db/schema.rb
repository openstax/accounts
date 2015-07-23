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

ActiveRecord::Schema.define(:version => 20150722224253) do

  create_table "application_groups", :force => true do |t|
    t.integer  "application_id",                :null => false
    t.integer  "group_id",                      :null => false
    t.integer  "unread_updates", :default => 1, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.index ["application_id", "unread_updates"], :name => "index_application_groups_on_application_id_and_unread_updates"
    t.index ["group_id", "application_id"], :name => "index_application_groups_on_group_id_and_application_id", :unique => true
    t.index ["group_id", "unread_updates"], :name => "index_application_groups_on_group_id_and_unread_updates"
  end

  create_table "application_users", :force => true do |t|
    t.integer  "application_id",                         :null => false
    t.integer  "user_id",                                :null => false
    t.integer  "default_contact_info_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "unread_updates",          :default => 1, :null => false
    t.index ["application_id", "unread_updates"], :name => "index_application_users_on_application_id_and_unread_updates"
    t.index ["application_id"], :name => "index_application_users_on_application_id"
    t.index ["default_contact_info_id"], :name => "index_application_users_on_default_contact_info_id"
    t.index ["user_id", "application_id"], :name => "index_application_users_on_user_id_and_application_id", :unique => true
    t.index ["user_id", "unread_updates"], :name => "index_application_users_on_user_id_and_unread_updates"
  end

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.index ["user_id", "provider"], :name => "index_authentications_on_user_id_scoped", :unique => true
  end

  create_table "contact_infos", :force => true do |t|
    t.string   "type"
    t.string   "value"
    t.boolean  "verified",             :default => false
    t.string   "confirmation_code"
    t.integer  "user_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.datetime "confirmation_sent_at"
    t.boolean  "is_searchable",        :default => false
    t.index ["confirmation_code"], :name => "index_contact_infos_on_confirmation_code", :unique => true
    t.index ["user_id"], :name => "index_contact_infos_on_user_id"
    t.index ["value", "user_id", "type"], :name => "index_contact_infos_on_value_user_id_type", :unique => true
  end

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
    t.index ["priority", "run_at"], :name => "delayed_jobs_priority"
  end

  create_table "fine_print_contracts", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "version"
    t.string   "title",      :null => false
    t.text     "content",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.index ["name", "version"], :name => "index_fine_print_contracts_on_name_and_version", :unique => true
  end

  create_table "fine_print_signatures", :force => true do |t|
    t.integer  "contract_id", :null => false
    t.integer  "user_id",     :null => false
    t.string   "user_type",   :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.index ["contract_id"], :name => "index_fine_print_signatures_on_contract_id"
    t.index ["user_id", "user_type", "contract_id"], :name => "index_fine_print_s_on_u_id_and_u_type_and_c_id", :unique => true
  end

  create_table "group_members", :force => true do |t|
    t.integer  "group_id",   :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.index ["group_id", "user_id"], :name => "index_group_members_on_group_id_and_user_id", :unique => true
    t.index ["user_id"], :name => "index_group_members_on_user_id"
  end

  create_table "group_nestings", :force => true do |t|
    t.integer  "member_group_id",    :null => false
    t.integer  "container_group_id", :null => false
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.index ["container_group_id"], :name => "index_group_nestings_on_container_group_id"
    t.index ["member_group_id"], :name => "index_group_nestings_on_member_group_id", :unique => true
  end

  create_table "group_owners", :force => true do |t|
    t.integer  "group_id",   :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.index ["group_id", "user_id"], :name => "index_group_owners_on_group_id_and_user_id", :unique => true
    t.index ["user_id"], :name => "index_group_owners_on_user_id"
  end

  create_table "groups", :force => true do |t|
    t.boolean  "is_public",                  :default => false, :null => false
    t.string   "name"
    t.text     "cached_subtree_group_ids"
    t.text     "cached_supertree_group_ids"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.index ["is_public"], :name => "index_groups_on_is_public"
  end

  create_table "identities", :force => true do |t|
    t.string   "password_digest"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "user_id",             :null => false
    t.datetime "password_expires_at"
    t.index ["user_id"], :name => "index_identities_on_user_id"
  end

  create_table "message_bodies", :force => true do |t|
    t.integer  "message_id",                 :null => false
    t.text     "html",       :default => "", :null => false
    t.text     "text",       :default => "", :null => false
    t.string   "short_text", :default => "", :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.index ["message_id"], :name => "index_message_bodies_on_message_id", :unique => true
  end

  create_table "message_recipients", :force => true do |t|
    t.integer  "message_id",                         :null => false
    t.integer  "contact_info_id"
    t.integer  "user_id"
    t.string   "recipient_type",                     :null => false
    t.boolean  "read",            :default => false, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.index ["contact_info_id", "message_id"], :name => "index_message_recipients_on_contact_info_id_and_message_id", :unique => true
    t.index ["message_id", "user_id"], :name => "index_message_recipients_on_message_id_and_user_id", :unique => true
    t.index ["user_id", "read"], :name => "index_message_recipients_on_user_id_and_read"
  end

  create_table "messages", :force => true do |t|
    t.integer  "application_id",                         :null => false
    t.integer  "user_id"
    t.boolean  "send_externally_now", :default => false, :null => false
    t.text     "subject",                                :null => false
    t.string   "subject_prefix",      :default => "",    :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.index ["application_id", "user_id"], :name => "index_messages_on_application_id_and_user_id"
    t.index ["user_id"], :name => "index_messages_on_user_id"
  end

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.text     "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
    t.index ["token"], :name => "index_oauth_access_grants_on_token", :unique => true
  end

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
    t.index ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
    t.index ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true
  end

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",                                    :null => false
    t.string   "uid",                                     :null => false
    t.string   "secret",                                  :null => false
    t.text     "redirect_uri",                            :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.boolean  "trusted",              :default => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "email_from_address",   :default => "",    :null => false
    t.string   "email_subject_prefix", :default => "",    :null => false
    t.boolean  "skip_terms",           :default => false, :null => false
    t.index ["owner_id", "owner_type"], :name => "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], :name => "index_oauth_applications_on_uid", :unique => true
  end

  create_table "password_reset_codes", :force => true do |t|
    t.integer  "identity_id", :null => false
    t.string   "code",        :null => false
    t.datetime "expires_at"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.index ["code"], :name => "index_password_reset_codes_on_code", :unique => true
    t.index ["identity_id"], :name => "index_password_reset_codes_on_identity_id", :unique => true
  end

  create_table "people", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "username",         :default => "",     :null => false
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "is_administrator", :default => false
    t.integer  "person_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "full_name"
    t.string   "title"
    t.string   "uuid"
    t.string   "suffix"
    t.string   "state",            :default => "temp", :null => false
    t.index ["first_name"], :name => "index_users_on_first_name", :case_sensitive => false
    t.index ["full_name"], :name => "index_users_on_full_name", :case_sensitive => false
    t.index ["last_name"], :name => "index_users_on_last_name", :case_sensitive => false
    t.index ["username"], :name => "index_users_on_username", :unique => true
    t.index ["username"], :name => "index_users_on_username_case_insensitive", :case_sensitive => false
    t.index ["uuid"], :name => "index_users_on_uuid", :unique => true
  end

end
