class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :status_page, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, default: 'investigating', limit: 20
      t.datetime :started_at, null: false
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :announcements, :status
  end
end
