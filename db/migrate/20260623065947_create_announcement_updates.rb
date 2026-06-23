class CreateAnnouncementUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_updates do |t|
      t.references :announcement, null: false, foreign_key: true
      t.text :content
      t.string :status

      t.timestamps
    end
  end
end
