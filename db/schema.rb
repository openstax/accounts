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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161201014148) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "application_groups", force: :cascade do |t|
    t.integer  "application_id", :null=>false, :index=>{:name=>"index_application_groups_on_application_id_and_unread_updates", :with=>["unread_updates"]}
    t.integer  "group_id",       :null=>false, :index=>{:name=>"index_application_groups_on_group_id_and_application_id", :with=>["application_id"], :unique=>true}
    t.integer  "unread_updates", :default=>1, :null=>false
    t.datetime "created_at",     :null=>false
    t.datetime "updated_at",     :null=>false
  end
  add_index "application_groups", ["group_id", "unread_updates"], :name=>"index_application_groups_on_group_id_and_unread_updates"

  create_table "application_users", force: :cascade do |t|
    t.integer  "application_id",          :null=>false, :index=>{:name=>"index_application_users_on_application_id"}
    t.integer  "user_id",                 :null=>false, :index=>{:name=>"index_application_users_on_user_id_and_application_id", :with=>["application_id"], :unique=>true}
    t.integer  "default_contact_info_id", :index=>{:name=>"index_application_users_on_default_contact_info_id"}
    t.datetime "created_at",              :null=>false
    t.datetime "updated_at",              :null=>false
    t.integer  "unread_updates",          :default=>1, :null=>false
  end
  add_index "application_users", ["application_id", "unread_updates"], :name=>"index_application_users_on_application_id_and_unread_updates"
  add_index "application_users", ["user_id", "unread_updates"], :name=>"index_application_users_on_user_id_and_unread_updates"

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",    :index=>{:name=>"index_authentications_on_user_id_scoped", :with=>["provider"], :unique=>true}
    t.string   "provider"
    t.string   "uid",        :index=>{:name=>"index_authentications_on_uid_scoped", :with=>["provider"], :unique=>true}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
    t.string   "login_hint"
  end

  create_table "contact_infos", force: :cascade do |t|
    t.string   "type"
    t.string   "value",                :index=>{:name=>"index_contact_infos_on_value_user_id_type", :with=>["user_id", "type"], :unique=>true}
    t.boolean  "verified",             :default=>false
    t.string   "confirmation_code",    :index=>{:name=>"index_contact_infos_on_confirmation_code", :unique=>true}
    t.integer  "user_id",              :index=>{:name=>"index_contact_infos_on_user_id"}
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
    t.datetime "confirmation_sent_at"
    t.boolean  "is_searchable",        :default=>false
    t.string   "confirmation_pin",     :index=>{:name=>"index_contact_infos_on_confirmation_pin"}
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   :default=>0, :null=>false, :index=>{:name=>"delayed_jobs_priority", :with=>["run_at"]}
    t.integer  "attempts",   :default=>0, :null=>false
    t.text     "handler",    :null=>false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fine_print_contracts", force: :cascade do |t|
    t.string   "name",       :null=>false, :index=>{:name=>"index_fine_print_contracts_on_name_and_version", :with=>["version"], :unique=>true}
    t.integer  "version"
    t.string   "title",      :null=>false
    t.text     "content",    :null=>false
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "fine_print_signatures", force: :cascade do |t|
    t.integer  "contract_id", :null=>false, :index=>{:name=>"index_fine_print_signatures_on_contract_id"}
    t.integer  "user_id",     :null=>false, :index=>{:name=>"index_fine_print_s_on_u_id_and_u_type_and_c_id", :with=>["user_type", "contract_id"], :unique=>true}
    t.string   "user_type",   :null=>false
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
    t.boolean  "is_implicit", :default=>false, :null=>false
  end

  create_table "group_members", force: :cascade do |t|
    t.integer  "group_id",   :null=>false, :index=>{:name=>"index_group_members_on_group_id_and_user_id", :with=>["user_id"], :unique=>true}
    t.integer  "user_id",    :null=>false, :index=>{:name=>"index_group_members_on_user_id"}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "group_nestings", force: :cascade do |t|
    t.integer  "member_group_id",    :null=>false, :index=>{:name=>"index_group_nestings_on_member_group_id", :unique=>true}
    t.integer  "container_group_id", :null=>false, :index=>{:name=>"index_group_nestings_on_container_group_id"}
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
  end

  create_table "group_owners", force: :cascade do |t|
    t.integer  "group_id",   :null=>false, :index=>{:name=>"index_group_owners_on_group_id_and_user_id", :with=>["user_id"], :unique=>true}
    t.integer  "user_id",    :null=>false, :index=>{:name=>"index_group_owners_on_user_id"}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "groups", force: :cascade do |t|
    t.boolean  "is_public",                  :default=>false, :null=>false, :index=>{:name=>"index_groups_on_is_public"}
    t.string   "name"
    t.text     "cached_subtree_group_ids"
    t.text     "cached_supertree_group_ids"
    t.datetime "created_at",                 :null=>false
    t.datetime "updated_at",                 :null=>false
  end

  create_table "identities", force: :cascade do |t|
    t.string   "password_digest"
    t.datetime "created_at",          :null=>false
    t.datetime "updated_at",          :null=>false
    t.integer  "user_id",             :null=>false, :index=>{:name=>"index_identities_on_user_id"}
    t.datetime "password_expires_at"
  end

  create_table "message_bodies", force: :cascade do |t|
    t.integer  "message_id", :null=>false, :index=>{:name=>"index_message_bodies_on_message_id", :unique=>true}
    t.text     "html",       :default=>"", :null=>false
    t.text     "text",       :default=>"", :null=>false
    t.string   "short_text", :default=>"", :null=>false
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "message_recipients", force: :cascade do |t|
    t.integer  "message_id",      :null=>false, :index=>{:name=>"index_message_recipients_on_message_id_and_user_id", :with=>["user_id"], :unique=>true}
    t.integer  "contact_info_id", :index=>{:name=>"index_message_recipients_on_contact_info_id_and_message_id", :with=>["message_id"], :unique=>true}
    t.integer  "user_id",         :index=>{:name=>"index_message_recipients_on_user_id_and_read", :with=>["read"]}
    t.string   "recipient_type",  :null=>false
    t.boolean  "read",            :default=>false, :null=>false
    t.datetime "created_at",      :null=>false
    t.datetime "updated_at",      :null=>false
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "application_id",      :null=>false, :index=>{:name=>"index_messages_on_application_id_and_user_id", :with=>["user_id"]}
    t.integer  "user_id",             :index=>{:name=>"index_messages_on_user_id"}
    t.boolean  "send_externally_now", :default=>false, :null=>false
    t.text     "subject",             :null=>false
    t.string   "subject_prefix",      :default=>"", :null=>false
    t.datetime "created_at",          :null=>false
    t.datetime "updated_at",          :null=>false
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", :null=>false
    t.integer  "application_id",    :null=>false
    t.string   "token",             :null=>false, :index=>{:name=>"index_oauth_access_grants_on_token", :unique=>true}
    t.integer  "expires_in",        :null=>false
    t.text     "redirect_uri",      :null=>false
    t.datetime "created_at",        :null=>false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", :index=>{:name=>"index_oauth_access_tokens_on_resource_owner_id"}
    t.integer  "application_id"
    t.string   "token",             :null=>false, :index=>{:name=>"index_oauth_access_tokens_on_token", :unique=>true}
    t.string   "refresh_token",     :index=>{:name=>"index_oauth_access_tokens_on_refresh_token", :unique=>true}
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null=>false
    t.string   "scopes"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                 :null=>false
    t.string   "uid",                  :null=>false, :index=>{:name=>"index_oauth_applications_on_uid", :unique=>true}
    t.string   "secret",               :null=>false
    t.text     "redirect_uri",         :null=>false
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
    t.boolean  "trusted",              :default=>false
    t.integer  "owner_id",             :index=>{:name=>"index_oauth_applications_on_owner_id_and_owner_type", :with=>["owner_type"]}
    t.string   "owner_type"
    t.string   "email_from_address",   :default=>"", :null=>false
    t.string   "email_subject_prefix", :default=>"", :null=>false
    t.boolean  "skip_terms",           :default=>false, :null=>false
    t.string   "scopes",               :default=>"", :null=>false
  end

  create_table "salesforce_users", force: :cascade do |t|
    t.string "name"
    t.string "uid",           :null=>false
    t.string "oauth_token",   :null=>false
    t.string "refresh_token", :null=>false
    t.string "instance_url",  :null=>false
  end

  create_table "security_logs", force: :cascade do |t|
    t.integer  "user_id",        :index=>{:name=>"index_security_logs_on_user_id_and_created_at", :with=>["created_at"]}
    t.integer  "application_id", :index=>{:name=>"index_security_logs_on_application_id_and_created_at", :with=>["created_at"]}
    t.string   "remote_ip",      :null=>false, :index=>{:name=>"index_security_logs_on_remote_ip_and_created_at", :with=>["created_at"]}
    t.integer  "event_type",     :null=>false, :index=>{:name=>"index_security_logs_on_event_type_and_created_at", :with=>["created_at"]}
    t.text     "event_data",     :default=>"{}", :null=>false
    t.datetime "created_at",     :null=>false, :index=>{:name=>"index_security_logs_on_created_at"}
  end

  create_table "sequential_failures", force: :cascade do |t|
    t.integer  "kind",       :null=>false, :index=>{:name=>"index_sequential_failures_on_kind_and_reference", :with=>["reference"], :unique=>true}
    t.string   "reference",  :null=>false
    t.integer  "length",     :default=>0
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "settings", force: :cascade do |t|
    t.string   "var",        :null=>false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", :limit=>30, :index=>{:name=>"index_settings_on_thing_type_and_thing_id_and_var", :with=>["thing_id", "var"], :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "signup_contact_infos", force: :cascade do |t|
    t.integer  "kind",                 :default=>0, :null=>false, :index=>{:name=>"index_signup_contact_infos_on_kind"}
    t.string   "value",                :null=>false
    t.boolean  "verified",             :default=>false
    t.string   "confirmation_code"
    t.string   "confirmation_pin"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",               :index=>{:name=>"index_users_on_username", :unique=>true}
    t.datetime "created_at",             :null=>false
    t.datetime "updated_at",             :null=>false
    t.boolean  "is_administrator",       :default=>false
    t.string   "first_name",             :index=>{:name=>"index_users_on_first_name", :case_sensitive=>false}
    t.string   "last_name",              :index=>{:name=>"index_users_on_last_name", :case_sensitive=>false}
    t.string   "title"
    t.string   "uuid",                   :index=>{:name=>"index_users_on_uuid", :unique=>true}
    t.string   "suffix"
    t.string   "state",                  :default=>"needs_profile", :null=>false
    t.string   "salesforce_contact_id",  :index=>{:name=>"index_users_on_salesforce_contact_id"}
    t.integer  "faculty_status",         :default=>0, :null=>false, :index=>{:name=>"index_users_on_faculty_status"}
    t.string   "self_reported_school"
    t.string   "login_token",            :index=>{:name=>"index_users_on_login_token", :unique=>true}
    t.datetime "login_token_expires_at"
    t.integer  "role",                   :default=>0, :null=>false, :index=>{:name=>"index_users_on_role"}
  end
  add_index "users", ["username"], :name=>"index_users_on_username_case_insensitive", :case_sensitive=>false

end
