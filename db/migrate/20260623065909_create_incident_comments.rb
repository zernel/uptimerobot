class CreateIncidentComments < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_comments do |t|
      t.references :incident, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
