class CreateAnnouncementUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_updates do |t|
      t.references :announcement, null: false, foreign_key: true
      t.text :content, null: false
      t.string :status, limit: 20

      t.timestamps
    end
  end
end
