class MonitorGroupsController < ApplicationController
  before_action :set_monitor_group, only: [:show, :edit, :update, :destroy]

  def index
    @monitor_groups = MonitorGroup.includes(:monitors).order(:sort_order)
  end

  def show
    @monitors = @monitor_group.monitors.includes(:tags).order(:name)
  end

  def new
    @monitor_group = MonitorGroup.new
  end

  def create
    @monitor_group = MonitorGroup.new(monitor_group_params)

    if @monitor_group.save
      redirect_to @monitor_group, notice: 'Monitor group was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @monitor_group.update(monitor_group_params)
      redirect_to @monitor_group, notice: 'Monitor group was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitor_group.destroy
    redirect_to monitor_groups_url, notice: 'Monitor group was successfully deleted.'
  end

  private

  def set_monitor_group
    @monitor_group = MonitorGroup.find(params[:id])
  end

  def monitor_group_params
    params.require(:monitor_group).permit(:name, :description, :sort_order)
  end
end
