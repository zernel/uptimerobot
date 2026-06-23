class AnnouncementsController < ApplicationController
  before_action :set_status_page
  before_action :set_announcement, only: [:show, :edit, :update, :destroy]

  def index
    @announcements = @status_page.announcements.order(started_at: :desc)
  end

  def show
    @updates = @announcement.announcement_updates.order(created_at: :asc)
  end

  def new
    @announcement = @status_page.announcements.build
  end

  def create
    @announcement = @status_page.announcements.build(announcement_params)

    if @announcement.save
      redirect_to [@status_page, @announcement], notice: 'Announcement was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to [@status_page, @announcement], notice: 'Announcement was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    redirect_to status_page_announcements_url(@status_page), notice: 'Announcement was successfully deleted.'
  end

  private

  def set_status_page
    @status_page = StatusPage.find(params[:status_page_id])
  end

  def set_announcement
    @announcement = @status_page.announcements.find(params[:id])
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :status, :started_at, :resolved_at)
  end
end
