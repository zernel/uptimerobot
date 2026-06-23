class StatusPagesController < ApplicationController
  before_action :set_status_page, only: [:show, :edit, :update, :destroy, :preview]

  def index
    @status_pages = StatusPage.order(:name)
  end

  def show
    @monitors = @status_page.monitors
                            .includes(:incidents)
                            .order(:name)
    @announcements = @status_page.announcements
                                 .where.not(status: 'resolved')
                                 .order(started_at: :desc)
  end

  def new
    @status_page = StatusPage.new
    @monitors = SiteMonitor.order(:name)
  end

  def create
    @status_page = StatusPage.new(status_page_params)

    if @status_page.save
      redirect_to @status_page, notice: 'Status page was successfully created.'
    else
      @monitors = SiteMonitor.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monitors = SiteMonitor.order(:name)
  end

  def update
    if @status_page.update(status_page_params)
      redirect_to @status_page, notice: 'Status page was successfully updated.'
    else
      @monitors = SiteMonitor.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @status_page.destroy
    redirect_to status_pages_url, notice: 'Status page was successfully deleted.'
  end

  def preview
    @monitors = @status_page.monitors
                            .includes(:incidents)
                            .order(:name)
    @announcements = @status_page.announcements
                                 .where.not(status: 'resolved')
                                 .order(started_at: :desc)
    render :show
  end

  private

  def set_status_page
    @status_page = StatusPage.find(params[:id])
  end

  def status_page_params
    params.require(:status_page).permit(
      :name, :slug, :logo_url, :favicon_url,
      :theme_color, :header_bg_color, :layout,
      :show_uptime_percentage, :show_response_time_graph,
      :show_monitor_url, :show_paused_monitors, :sort_by,
      :password, :google_analytics_id, :noindex, :published,
      monitor_ids: []
    )
  end
end
