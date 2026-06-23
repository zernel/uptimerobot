class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :status_page, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :status
      t.datetime :started_at
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
