class CreateCheckResults < ActiveRecord::Migration[8.1]
  def change
    create_table :check_results do |t|
      t.references :monitor, null: false, foreign_key: true
      t.string :status, null: false, limit: 20
      t.integer :response_time
      t.text :error_message
      t.jsonb :metadata
      t.datetime :checked_at, null: false

      t.timestamps
    end

    add_index :check_results, [:monitor_id, :checked_at], order: { checked_at: :desc }
    add_index :check_results, [:monitor_id, :id], order: { id: :desc }
  end
end
