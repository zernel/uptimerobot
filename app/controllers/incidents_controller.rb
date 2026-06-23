class IncidentsController < ApplicationController
  def index
    @incidents = Incident.includes(:monitor)
                         .order(started_at: :desc)
                         .page(params[:page])

    if params[:status].present?
      @incidents = @incidents.where(status: params[:status])
    end

    if params[:monitor_id].present?
      @incidents = @incidents.where(monitor_id: params[:monitor_id])
    end
  end

  def show
    @incident = Incident.find(params[:id])
    @comments = @incident.incident_comments.order(created_at: :asc)
    @notification_logs = @incident.notification_logs
                                  .includes(:notification_channel)
                                  .order(sent_at: :desc)
  end
end
