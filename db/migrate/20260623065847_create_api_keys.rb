class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_digest, null: false
      t.string :key_prefix, null: false, limit: 8
      t.jsonb :permissions, default: '["read", "write"]'
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :api_keys, :key_digest, unique: true
  end
end
