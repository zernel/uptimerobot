class CreateResponseTimeStats < ActiveRecord::Migration[8.1]
  def change
    create_table :response_time_stats do |t|
      t.references :monitor, null: false, foreign_key: true
      t.string :period_type, null: false, limit: 10
      t.datetime :period_start, null: false
      t.integer :avg_response_time
      t.integer :min_response_time
      t.integer :max_response_time
      t.integer :p95_response_time
      t.integer :check_count

      t.timestamps
    end

    add_index :response_time_stats, [:monitor_id, :period_type, :period_start], unique: true, name: 'idx_response_time_stats_unique'
  end
end
