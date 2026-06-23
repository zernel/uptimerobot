class MonitorsController < ApplicationController
  before_action :set_monitor, only: [:show, :edit, :update, :destroy, :pause, :resume, :reset]

  def index
    @monitors = SiteMonitor.includes(:monitor_group, :tags)
                       .order(:name)
                       .page(params[:page])

    if params[:status].present?
      @monitors = @monitors.where(status: params[:status])
    end

    if params[:type].present?
      @monitors = @monitors.where(monitor_type: params[:type])
    end

    if params[:group_id].present?
      @monitors = @monitors.where(monitor_group_id: params[:group_id])
    end
  end

  def show
    @check_results = @monitor.check_results.order(checked_at: :desc).limit(100)
    @incidents = @monitor.incidents.order(started_at: :desc).limit(20)
    @response_time_stats = @monitor.response_time_stats
                                    .where(period_type: 'hourly')
                                    .order(period_start: :desc)
                                    .limit(24)
  end

  def new
    @monitor = SiteMonitor.new
    @monitor_groups = MonitorGroup.all
    @tags = Tag.all
  end

  def create
    @monitor = SiteMonitor.new(monitor_params)

    if @monitor.save
      redirect_to monitor_url(@monitor), notice: 'Monitor was successfully created.'
    else
      @monitor_groups = MonitorGroup.all
      @tags = Tag.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monitor_groups = MonitorGroup.all
    @tags = Tag.all
  end

  def update
    if @monitor.update(monitor_params)
      redirect_to monitor_url(@monitor), notice: 'Monitor was successfully updated.'
    else
      @monitor_groups = MonitorGroup.all
      @tags = Tag.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitor.destroy
    redirect_to monitors_url, notice: 'Monitor was successfully deleted.'
  end

  def pause
    @monitor.update!(paused: true, status: 'paused')
    redirect_to monitor_url(@monitor), notice: 'Monitor paused.'
  end

  def resume
    @monitor.update!(paused: false, status: 'pending')
    redirect_to monitor_url(@monitor), notice: 'Monitor resumed.'
  end

  def reset
    @monitor.update!(consecutive_failures: 0, status: 'pending')
    redirect_to monitor_url(@monitor), notice: 'Monitor reset.'
  end

  private

  def set_monitor
    @monitor = SiteMonitor.find(params[:id])
  end

  def monitor_params
    params.require(:monitor).permit(
      :name, :monitor_type, :url, :hostname, :port,
      :http_method, :http_headers, :http_body, :follow_redirects, :verify_ssl,
      :keyword, :keyword_type,
      :api_assertions,
      :heartbeat_interval,
      :alert_days_before,
      :dns_record_type, :dns_expected_value,
      :interval, :timeout, :retries,
      :alert_threshold, :alert_delay,
      :monitor_group_id, :description, :paused,
      tag_ids: []
    )
  end
end
