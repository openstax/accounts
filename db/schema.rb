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

ActiveRecord::Schema.define(version: 2022_06_01_160740) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_trgm"
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

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
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
    t.boolean "is_school_issued", comment: "User claims to be a school-issued email address"
    t.index "lower((value)::text), verified", name: "index_contact_infos_on_value_and_verified_case_insensitive"
    t.index ["confirmation_code"], name: "index_contact_infos_on_confirmation_code", unique: true
    t.index ["confirmation_pin"], name: "index_contact_infos_on_confirmation_pin"
    t.index ["is_school_issued"], name: "index_contact_infos_on_is_school_issued"
    t.index ["user_id"], name: "index_contact_infos_on_user_id"
    t.index ["value", "user_id", "type"], name: "index_contact_infos_on_value_user_id_type", unique: true
    t.index ["verified"], name: "index_contact_infos_on_verified"
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

  create_table "delayed_workers", force: :cascade do |t|
    t.string "name"
    t.string "version"
    t.datetime "last_heartbeat_at"
    t.string "host_name"
    t.string "label"
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
    t.integer "owner_id"
    t.string "owner_type"
    t.string "email_from_address", default: "", null: false
    t.string "email_subject_prefix", default: "", null: false
    t.boolean "skip_terms", default: false, null: false
    t.string "scopes", default: "", null: false
    t.string "lead_application_source", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.boolean "can_access_private_user_data", default: false, null: false
    t.boolean "can_find_or_create_accounts", default: false, null: false
    t.boolean "can_message_users", default: false, null: false
    t.boolean "can_skip_oauth_screen", default: false, null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "push_topics", force: :cascade do |t|
    t.string "topic_salesforce_id"
    t.string "topic_name"
  end

  create_table "schools", force: :cascade do |t|
    t.string "salesforce_id", null: false
    t.string "name", null: false
    t.string "city"
    t.string "state"
    t.string "type"
    t.string "location"
    t.string "sheerid_school_name"
    t.boolean "is_kip", null: false
    t.boolean "is_child_of_kip", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country", default: "United States", null: false
    t.index ["name", "city", "state"], name: "index_schools_on_name_and_city_and_state", opclass: :gist_trgm_ops, using: :gist
    t.index ["salesforce_id"], name: "index_schools_on_salesforce_id", unique: true
    t.index ["sheerid_school_name"], name: "index_schools_on_sheerid_school_name"
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

  create_table "sheerid_verifications", force: :cascade do |t|
    t.string "verification_id", null: false
    t.string "email"
    t.string "current_step"
    t.string "first_name"
    t.string "last_name"
    t.string "organization_name"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
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
    t.string "state", default: "unverified", null: false
    t.string "salesforce_contact_id"
    t.integer "faculty_status", default: 0, null: false
    t.string "self_reported_school"
    t.string "login_token"
    t.datetime "login_token_expires_at"
    t.integer "role", default: 0, null: false
    t.jsonb "signed_external_data"
    t.boolean "is_test"
    t.integer "school_type", default: 0, null: false
    t.boolean "using_openstax", default: false
    t.boolean "receive_newsletter"
    t.bigint "source_application_id"
    t.datetime "activated_at"
    t.string "phone_number"
    t.boolean "is_kip", comment: "is the User-s school a Key Institutional Partner?"
    t.string "country_code"
    t.integer "school_location", default: 0, null: false
    t.string "sheerid_reported_school"
    t.string "sheerid_verification_id"
    t.boolean "opt_out_of_cookies", default: false
    t.string "salesforce_lead_id"
    t.string "other_role_name"
    t.string "how_many_students"
    t.string "which_books"
    t.string "who_chooses_books"
    t.integer "using_openstax_how"
    t.boolean "is_profile_complete"
    t.boolean "is_educator_pending_cs_verification"
    t.boolean "is_sheerid_unviable"
    t.boolean "is_sheerid_verified"
    t.boolean "grant_tutor_access"
    t.datetime "requested_cs_verification_at"
    t.boolean "is_b_r_i_user"
    t.boolean "title_1_school"
    t.bigint "school_id"
    t.boolean "sheer_id_webhook_received"
    t.string "salesforce_ox_account_id"
    t.boolean "renewal_eligible"
    t.index "lower((first_name)::text)", name: "index_users_on_first_name"
    t.index "lower((last_name)::text)", name: "index_users_on_last_name"
    t.index "lower((username)::text)", name: "index_users_on_username_case_insensitive"
    t.index ["faculty_status"], name: "index_users_on_faculty_status"
    t.index ["login_token"], name: "index_users_on_login_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["salesforce_contact_id"], name: "index_users_on_salesforce_contact_id"
    t.index ["salesforce_ox_account_id"], name: "index_users_on_salesforce_ox_account_id"
    t.index ["school_id"], name: "index_users_on_school_id"
    t.index ["school_type"], name: "index_users_on_school_type"
    t.index ["source_application_id"], name: "index_users_on_source_application_id"
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "users", "oauth_applications", column: "source_application_id"
  add_foreign_key "users", "schools"
end
