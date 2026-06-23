class AddIdToMonitorTags < ActiveRecord::Migration[8.1]
  def change
    add_column :monitor_tags, :id, :primary_key
  end
end
