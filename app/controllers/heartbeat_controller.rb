class HeartbeatController < ApplicationController
  skip_before_action :authenticate_user!

  def ping
    monitor = SiteMonitor.find_by(heartbeat_token: params[:token])

    if monitor
      monitor.update!(last_heartbeat_at: Time.current)
      render json: { status: 'ok' }
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end
