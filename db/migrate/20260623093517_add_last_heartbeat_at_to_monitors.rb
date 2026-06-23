class AddLastHeartbeatAtToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :last_heartbeat_at, :datetime
  end
end
