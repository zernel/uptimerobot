class CreateStatusPages < ActiveRecord::Migration[8.1]
  def change
    create_table :status_pages do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :logo_url, limit: 2048
      t.string :favicon_url, limit: 2048
      t.string :theme_color, default: '#1F2937', limit: 7
      t.string :header_bg_color, default: '#1F2937', limit: 7
      t.string :layout, default: 'wide', limit: 20
      t.boolean :show_uptime_percentage, default: true
      t.boolean :show_response_time_graph, default: true
      t.boolean :show_monitor_url, default: false
      t.boolean :show_paused_monitors, default: false
      t.string :sort_by, default: 'status', limit: 20
      t.string :password_digest
      t.string :google_analytics_id, limit: 50
      t.boolean :noindex, default: false
      t.boolean :published, default: false

      t.timestamps
    end

    add_index :status_pages, :slug, unique: true
  end
end
