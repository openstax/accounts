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

ActiveRecord::Schema.define(version: 2019_02_06_185243) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "application_groups", id: :serial, force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "group_id", null: false
    t.integer "unread_updates", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "unread_updates"], name: "index_application_groups_on_application_id_and_unread_updates"
    t.index ["group_id", "application_id"], name: "index_application_groups_on_group_id_and_application_id", unique: true
    t.index ["group_id", "unread_updates"], name: "index_application_groups_on_group_id_and_unread_updates"
  end

  create_table "application_users", id: :serial, force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "user_id", null: false
    t.integer "default_contact_info_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unread_updates", default: 1, null: false
    t.index ["application_id", "unread_updates"], name: "index_application_users_on_application_id_and_unread_updates"
    t.index ["application_id"], name: "index_application_users_on_application_id"
    t.index ["default_contact_info_id"], name: "index_application_users_on_default_contact_info_id"
    t.index ["user_id", "application_id"], name: "index_application_users_on_user_id_and_application_id", unique: true
    t.index ["user_id", "unread_updates"], name: "index_application_users_on_user_id_and_unread_updates"
  end

  create_table "authentications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "login_hint"
    t.index ["uid", "provider"], name: "index_authentications_on_uid_scoped", unique: true
    t.index ["user_id", "provider"], name: "index_authentications_on_user_id_scoped", unique: true
  end

  create_table "banners", id: :serial, force: :cascade do |t|
    t.string "message", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_banners_on_expires_at"
  end

  create_table "contact_infos", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "value"
    t.boolean "verified", default: false
    t.string "confirmation_code"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmation_sent_at"
    t.boolean "is_searchable", default: false
    t.string "confirmation_pin"
    t.index "lower((value)::text), verified", name: "index_contact_infos_on_value_and_verified_case_insensitive"
    t.index ["confirmation_code"], name: "index_contact_infos_on_confirmation_code", unique: true
    t.index ["confirmation_pin"], name: "index_contact_infos_on_confirmation_pin"
    t.index ["user_id"], name: "index_contact_infos_on_user_id"
    t.index ["value", "user_id", "type"], name: "index_contact_infos_on_value_user_id_type", unique: true
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "email_domains", id: :serial, force: :cascade do |t|
    t.string "value", default: ""
    t.boolean "has_mx", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fine_print_contracts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "version"
    t.string "title", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "version"], name: "index_fine_print_contracts_on_name_and_version", unique: true
  end

  create_table "fine_print_signatures", id: :serial, force: :cascade do |t|
    t.integer "contract_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_implicit", default: false, null: false
    t.index ["contract_id"], name: "index_fine_print_signatures_on_contract_id"
    t.index ["user_id", "user_type", "contract_id"], name: "index_fine_print_s_on_u_id_and_u_type_and_c_id", unique: true
  end

  create_table "group_members", id: :serial, force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_members_on_group_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_group_members_on_user_id"
  end

  create_table "group_nestings", id: :serial, force: :cascade do |t|
    t.integer "member_group_id", null: false
    t.integer "container_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["container_group_id"], name: "index_group_nestings_on_container_group_id"
    t.index ["member_group_id"], name: "index_group_nestings_on_member_group_id", unique: true
  end

  create_table "group_owners", id: :serial, force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_owners_on_group_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_group_owners_on_user_id"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.boolean "is_public", default: false, null: false
    t.string "name"
    t.text "cached_subtree_group_ids"
    t.text "cached_supertree_group_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_public"], name: "index_groups_on_is_public"
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.datetime "password_expires_at"
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "message_bodies", id: :serial, force: :cascade do |t|
    t.integer "message_id", null: false
    t.text "html", default: "", null: false
    t.text "text", default: "", null: false
    t.string "short_text", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_bodies_on_message_id", unique: true
  end

  create_table "message_recipients", id: :serial, force: :cascade do |t|
    t.integer "message_id", null: false
    t.integer "contact_info_id"
    t.integer "user_id"
    t.string "recipient_type", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_info_id", "message_id"], name: "index_message_recipients_on_contact_info_id_and_message_id", unique: true
    t.index ["message_id", "user_id"], name: "index_message_recipients_on_message_id_and_user_id", unique: true
    t.index ["user_id", "read"], name: "index_message_recipients_on_user_id_and_read"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "application_id", null: false
    t.integer "user_id"
    t.boolean "send_externally_now", default: false, null: false
    t.text "subject", null: false
    t.string "subject_prefix", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "user_id"], name: "index_messages_on_application_id_and_user_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "oauth_access_grants", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id", "created_at"], name: "index_oauth_access_tokens_on_application_id_and_created_at", where: "((resource_owner_id IS NULL) AND (revoked_at IS NULL))"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "trusted", default: false
    t.integer "owner_id"
    t.string "owner_type"
    t.string "email_from_address", default: "", null: false
    t.string "email_subject_prefix", default: "", null: false
    t.boolean "skip_terms", default: false, null: false
    t.string "scopes", default: "", null: false
    t.string "lead_application_source", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "openstax_salesforce_users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "uid", null: false
    t.string "oauth_token", null: false
    t.string "refresh_token", null: false
    t.string "instance_url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pre_auth_states", id: :serial, force: :cascade do |t|
    t.integer "contact_info_kind", default: 0
    t.string "contact_info_value"
    t.boolean "is_contact_info_verified", default: false
    t.string "confirmation_code"
    t.string "confirmation_pin"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", null: false
    t.text "return_to"
    t.jsonb "signed_data"
    t.boolean "is_partial_info_allowed", default: false, null: false
    t.index ["contact_info_kind"], name: "index_pre_auth_states_on_contact_info_kind"
  end

  create_table "security_logs", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "application_id"
    t.string "remote_ip"
    t.integer "event_type", null: false
    t.text "event_data", default: "{}", null: false
    t.datetime "created_at", null: false
    t.index ["application_id", "created_at"], name: "index_security_logs_on_application_id_and_created_at"
    t.index ["created_at"], name: "index_security_logs_on_created_at"
    t.index ["event_type", "created_at"], name: "index_security_logs_on_event_type_and_created_at"
    t.index ["remote_ip", "created_at"], name: "index_security_logs_on_remote_ip_and_created_at"
    t.index ["user_id", "created_at"], name: "index_security_logs_on_user_id_and_created_at"
  end

  create_table "sequential_failures", id: :serial, force: :cascade do |t|
    t.integer "kind", null: false
    t.string "reference", null: false
    t.integer "length", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "reference"], name: "index_sequential_failures_on_kind_and_reference", unique: true
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.integer "thing_id"
    t.string "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "user_external_uuids", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_user_external_uuids_on_uuid"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_administrator", default: false
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "suffix"
    t.string "state", default: "needs_profile", null: false
    t.string "salesforce_contact_id"
    t.integer "faculty_status", default: 0, null: false
    t.string "self_reported_school"
    t.string "login_token"
    t.datetime "login_token_expires_at"
    t.integer "role", default: 0, null: false
    t.jsonb "signed_external_data"
    t.citext "support_identifier", null: false
    t.boolean "is_test"
    t.integer "school_type", default: 0, null: false
    t.index "lower((first_name)::text)", name: "index_users_on_first_name"
    t.index "lower((last_name)::text)", name: "index_users_on_last_name"
    t.index "lower((username)::text)", name: "index_users_on_username_case_insensitive"
    t.index ["faculty_status"], name: "index_users_on_faculty_status"
    t.index ["login_token"], name: "index_users_on_login_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["salesforce_contact_id"], name: "index_users_on_salesforce_contact_id"
    t.index ["school_type"], name: "index_users_on_school_type"
    t.index ["support_identifier"], name: "index_users_on_support_identifier", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
