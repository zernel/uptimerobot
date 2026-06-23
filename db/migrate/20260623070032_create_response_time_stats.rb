class CreateResponseTimeStats < ActiveRecord::Migration[8.1]
  def change
    create_table :response_time_stats do |t|
      t.references :monitor, null: false, foreign_key: true
      t.string :period_type
      t.datetime :period_start
      t.integer :avg_response_time
      t.integer :min_response_time
      t.integer :max_response_time
      t.integer :p95_response_time
      t.integer :check_count

      t.timestamps
    end
  end
end
