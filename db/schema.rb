# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_23_093517) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcement_updates", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "status", limit: 20
    t.datetime "updated_at", null: false
    t.index ["announcement_id"], name: "index_announcement_updates_on_announcement_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "resolved_at"
    t.datetime "started_at", null: false
    t.string "status", limit: 20, default: "investigating"
    t.bigint "status_page_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_announcements_on_status"
    t.index ["status_page_id"], name: "index_announcements_on_status_page_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "key_digest", null: false
    t.string "key_prefix", limit: 8, null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.jsonb "permissions", default: "[\"read\", \"write\"]"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "check_results", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.jsonb "metadata"
    t.bigint "monitor_id", null: false
    t.integer "response_time"
    t.string "status", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["monitor_id", "checked_at"], name: "index_check_results_on_monitor_id_and_checked_at", order: { checked_at: :desc }
    t.index ["monitor_id", "id"], name: "index_check_results_on_monitor_id_and_id", order: { id: :desc }
    t.index ["monitor_id"], name: "index_check_results_on_monitor_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "incident_comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "incident_id", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id"], name: "index_incident_comments_on_incident_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.string "cause", limit: 50
    t.text "cause_detail"
    t.datetime "created_at", null: false
    t.integer "duration"
    t.boolean "excluded_from_report", default: false
    t.bigint "monitor_id", null: false
    t.datetime "resolved_at"
    t.datetime "started_at", null: false
    t.string "status", limit: 20, default: "ongoing"
    t.jsonb "tags", default: "[]"
    t.datetime "updated_at", null: false
    t.index ["monitor_id"], name: "index_incidents_on_monitor_id"
    t.index ["started_at"], name: "index_incidents_on_started_at", order: :desc
    t.index ["status"], name: "index_incidents_on_status"
  end

  create_table "maintenance_windows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at", null: false
    t.jsonb "monitor_ids", default: "[]"
    t.string "name", null: false
    t.string "recurrence", limit: 20
    t.datetime "recurrence_end_at"
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ends_at"], name: "index_maintenance_windows_on_ends_at"
    t.index ["starts_at"], name: "index_maintenance_windows_on_starts_at"
  end

  create_table "monitor_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "sort_order"
    t.datetime "updated_at", null: false
  end

  create_table "monitor_notification_channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "monitor_id", null: false
    t.bigint "notification_channel_id", null: false
    t.boolean "notify_on_domain_expiry", default: true
    t.boolean "notify_on_down", default: true
    t.boolean "notify_on_ssl_expiry", default: true
    t.boolean "notify_on_up", default: true
    t.datetime "updated_at", null: false
    t.index ["monitor_id", "notification_channel_id"], name: "idx_monitor_notification_channels_unique", unique: true
    t.index ["monitor_id"], name: "index_monitor_notification_channels_on_monitor_id"
    t.index ["notification_channel_id"], name: "index_monitor_notification_channels_on_notification_channel_id"
  end

  create_table "monitor_tags", force: :cascade do |t|
    t.bigint "monitor_id", null: false
    t.bigint "tag_id", null: false
    t.index ["monitor_id", "tag_id"], name: "index_monitor_tags_on_monitor_id_and_tag_id", unique: true
    t.index ["monitor_id"], name: "index_monitor_tags_on_monitor_id"
    t.index ["tag_id"], name: "index_monitor_tags_on_tag_id"
  end

  create_table "monitors", force: :cascade do |t|
    t.integer "alert_days_before", default: 30
    t.integer "alert_delay", default: 0
    t.integer "alert_threshold", default: 1
    t.jsonb "api_assertions"
    t.integer "consecutive_failures", default: 0
    t.datetime "created_at", null: false
    t.text "description"
    t.string "dns_expected_value"
    t.string "dns_record_type", limit: 10
    t.boolean "follow_redirects", default: true
    t.integer "heartbeat_interval"
    t.string "heartbeat_token", limit: 64
    t.string "hostname"
    t.text "http_body"
    t.jsonb "http_headers"
    t.string "http_method", limit: 10, default: "GET"
    t.integer "interval", default: 300
    t.string "keyword"
    t.string "keyword_type", limit: 10
    t.datetime "last_check_at"
    t.datetime "last_heartbeat_at"
    t.datetime "last_status_change_at"
    t.bigint "monitor_group_id"
    t.string "monitor_type", limit: 50, null: false
    t.string "name", null: false
    t.boolean "paused", default: false
    t.integer "port"
    t.integer "response_time"
    t.integer "retries", default: 2
    t.string "status", limit: 20, default: "pending"
    t.integer "timeout", default: 30
    t.datetime "updated_at", null: false
    t.decimal "uptime_24h", precision: 5, scale: 2
    t.decimal "uptime_30d", precision: 5, scale: 2
    t.decimal "uptime_7d", precision: 5, scale: 2
    t.string "url", limit: 2048
    t.boolean "verify_ssl", default: true
    t.index ["heartbeat_token"], name: "index_monitors_on_heartbeat_token", unique: true
    t.index ["monitor_group_id"], name: "index_monitors_on_monitor_group_id"
    t.index ["paused"], name: "index_monitors_on_paused"
    t.index ["status"], name: "index_monitors_on_status"
  end

  create_table "notification_channels", force: :cascade do |t|
    t.string "channel_type", limit: 50, null: false
    t.jsonb "config", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.text "last_error"
    t.datetime "last_used_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.bigint "incident_id"
    t.text "message"
    t.bigint "monitor_id", null: false
    t.bigint "notification_channel_id", null: false
    t.datetime "sent_at", null: false
    t.string "status", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id"], name: "index_notification_logs_on_incident_id"
    t.index ["monitor_id"], name: "index_notification_logs_on_monitor_id"
    t.index ["notification_channel_id"], name: "index_notification_logs_on_notification_channel_id"
    t.index ["sent_at"], name: "index_notification_logs_on_sent_at", order: :desc
  end

  create_table "response_time_stats", force: :cascade do |t|
    t.integer "avg_response_time"
    t.integer "check_count"
    t.datetime "created_at", null: false
    t.integer "max_response_time"
    t.integer "min_response_time"
    t.bigint "monitor_id", null: false
    t.integer "p95_response_time"
    t.datetime "period_start", null: false
    t.string "period_type", limit: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["monitor_id", "period_type", "period_start"], name: "idx_response_time_stats_unique", unique: true
    t.index ["monitor_id"], name: "index_response_time_stats_on_monitor_id"
  end

  create_table "status_page_monitors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "monitor_id", null: false
    t.integer "sort_order", default: 0
    t.bigint "status_page_id", null: false
    t.datetime "updated_at", null: false
    t.index ["monitor_id"], name: "index_status_page_monitors_on_monitor_id"
    t.index ["status_page_id", "monitor_id"], name: "idx_status_page_monitors_unique", unique: true
    t.index ["status_page_id"], name: "index_status_page_monitors_on_status_page_id"
  end

  create_table "status_pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "favicon_url", limit: 2048
    t.string "google_analytics_id", limit: 50
    t.string "header_bg_color", limit: 7, default: "#1F2937"
    t.string "layout", limit: 20, default: "wide"
    t.string "logo_url", limit: 2048
    t.string "name", null: false
    t.boolean "noindex", default: false
    t.string "password_digest"
    t.boolean "published", default: false
    t.boolean "show_monitor_url", default: false
    t.boolean "show_paused_monitors", default: false
    t.boolean "show_response_time_graph", default: true
    t.boolean "show_uptime_percentage", default: true
    t.string "slug", null: false
    t.string "sort_by", limit: 20, default: "status"
    t.string "theme_color", limit: 7, default: "#1F2937"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_status_pages_on_slug", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "color", limit: 7, default: "#6B7280"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "announcement_updates", "announcements"
  add_foreign_key "announcements", "status_pages"
  add_foreign_key "api_keys", "users"
  add_foreign_key "check_results", "monitors"
  add_foreign_key "incident_comments", "incidents"
  add_foreign_key "incidents", "monitors"
  add_foreign_key "monitor_notification_channels", "monitors"
  add_foreign_key "monitor_notification_channels", "notification_channels"
  add_foreign_key "monitor_tags", "monitors"
  add_foreign_key "monitor_tags", "tags"
  add_foreign_key "monitors", "monitor_groups"
  add_foreign_key "notification_logs", "incidents"
  add_foreign_key "notification_logs", "monitors"
  add_foreign_key "notification_logs", "notification_channels"
  add_foreign_key "response_time_stats", "monitors"
  add_foreign_key "status_page_monitors", "monitors"
  add_foreign_key "status_page_monitors", "status_pages"
end
