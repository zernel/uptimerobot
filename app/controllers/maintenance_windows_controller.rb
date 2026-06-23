class MaintenanceWindowsController < ApplicationController
  before_action :set_maintenance_window, only: [:show, :edit, :update, :destroy]

  def index
    @maintenance_windows = MaintenanceWindow.order(starts_at: :desc)
    @active_windows = MaintenanceWindow.active
    @upcoming_windows = MaintenanceWindow.upcoming
  end

  def show
  end

  def new
    @maintenance_window = MaintenanceWindow.new
    @monitors = SiteMonitor.order(:name)
  end

  def create
    @maintenance_window = MaintenanceWindow.new(maintenance_window_params)

    if @maintenance_window.save
      redirect_to @maintenance_window, notice: 'Maintenance window was successfully created.'
    else
      @monitors = SiteMonitor.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @monitors = SiteMonitor.order(:name)
  end

  def update
    if @maintenance_window.update(maintenance_window_params)
      redirect_to @maintenance_window, notice: 'Maintenance window was successfully updated.'
    else
      @monitors = SiteMonitor.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @maintenance_window.destroy
    redirect_to maintenance_windows_url, notice: 'Maintenance window was successfully deleted.'
  end

  private

  def set_maintenance_window
    @maintenance_window = MaintenanceWindow.find(params[:id])
  end

  def maintenance_window_params
    params.require(:maintenance_window).permit(
      :name, :description, :starts_at, :ends_at,
      :recurrence, :recurrence_end_at,
      monitor_ids: []
    )
  end
end
