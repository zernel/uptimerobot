class NotificationChannelsController < ApplicationController
  before_action :set_notification_channel, only: [:show, :edit, :update, :destroy]

  def index
    @notification_channels = NotificationChannel.order(:name)
  end

  def show
    @notification_logs = @notification_channel.notification_logs
                                              .includes(:monitor, :incident)
                                              .order(sent_at: :desc)
                                              .limit(50)
  end

  def new
    @notification_channel = NotificationChannel.new
  end

  def create
    @notification_channel = NotificationChannel.new(notification_channel_params)

    if @notification_channel.save
      redirect_to @notification_channel, notice: 'Notification channel was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @notification_channel.update(notification_channel_params)
      redirect_to @notification_channel, notice: 'Notification channel was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notification_channel.destroy
    redirect_to notification_channels_url, notice: 'Notification channel was successfully deleted.'
  end

  private

  def set_notification_channel
    @notification_channel = NotificationChannel.find(params[:id])
  end

  def notification_channel_params
    params.require(:notification_channel).permit(
      :name, :channel_type, :enabled,
      config: [:address, :webhook_url, :channel]
    )
  end
end
