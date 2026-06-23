class CreateIncidents < ActiveRecord::Migration[8.1]
  def change
    create_table :incidents do |t|
      t.references :monitor, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :resolved_at
      t.integer :duration
      t.string :cause
      t.text :cause_detail
      t.jsonb :tags
      t.boolean :excluded_from_report

      t.timestamps
    end
  end
end
