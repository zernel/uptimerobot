class CreateStatusPages < ActiveRecord::Migration[8.1]
  def change
    create_table :status_pages do |t|
      t.string :name
      t.string :slug
      t.string :logo_url
      t.string :favicon_url
      t.string :theme_color
      t.string :header_bg_color
      t.string :layout
      t.boolean :show_uptime_percentage
      t.boolean :show_response_time_graph
      t.boolean :show_monitor_url
      t.boolean :show_paused_monitors
      t.string :sort_by
      t.string :password_digest
      t.string :google_analytics_id
      t.boolean :noindex
      t.boolean :published

      t.timestamps
    end
  end
end
