class CreateIncidents < ActiveRecord::Migration[8.1]
  def change
    create_table :incidents do |t|
      t.references :monitor, null: false, foreign_key: true
      t.string :status, default: 'ongoing', limit: 20
      t.datetime :started_at, null: false
      t.datetime :resolved_at
      t.integer :duration
      t.string :cause, limit: 50
      t.text :cause_detail
      t.jsonb :tags, default: '[]'
      t.boolean :excluded_from_report, default: false

      t.timestamps
    end

    add_index :incidents, :status
    add_index :incidents, :started_at, order: { started_at: :desc }
  end
end
