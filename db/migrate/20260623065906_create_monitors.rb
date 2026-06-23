class CreateMonitors < ActiveRecord::Migration[8.1]
  def change
    create_table :monitors do |t|
      t.string :name, null: false
      t.string :monitor_type, null: false, limit: 50
      t.string :status, default: 'pending', limit: 20
      t.string :url, limit: 2048
      t.string :hostname
      t.integer :port
      t.string :http_method, default: 'GET', limit: 10
      t.jsonb :http_headers
      t.text :http_body
      t.boolean :follow_redirects, default: true
      t.boolean :verify_ssl, default: true
      t.string :keyword
      t.string :keyword_type, limit: 10
      t.jsonb :api_assertions
      t.string :heartbeat_token, limit: 64
      t.integer :heartbeat_interval
      t.integer :alert_days_before, default: 30
      t.string :dns_record_type, limit: 10
      t.string :dns_expected_value
      t.integer :interval, default: 300
      t.integer :timeout, default: 30
      t.integer :retries, default: 2
      t.integer :alert_threshold, default: 1
      t.integer :alert_delay, default: 0
      t.datetime :last_check_at
      t.datetime :last_status_change_at
      t.integer :consecutive_failures, default: 0
      t.integer :response_time
      t.references :monitor_group, foreign_key: true
      t.decimal :uptime_24h, precision: 5, scale: 2
      t.decimal :uptime_7d, precision: 5, scale: 2
      t.decimal :uptime_30d, precision: 5, scale: 2
      t.text :description
      t.boolean :paused, default: false

      t.timestamps
    end

    add_index :monitors, :status
    add_index :monitors, :heartbeat_token, unique: true
    add_index :monitors, :paused
  end
end
