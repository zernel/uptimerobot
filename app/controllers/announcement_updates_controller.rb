class AnnouncementUpdatesController < ApplicationController
  def create
    @announcement = Announcement.find(params[:announcement_id])
    @update = @announcement.announcement_updates.build(update_params)

    if @update.save
      redirect_to [@announcement.status_page, @announcement], notice: 'Update added.'
    else
      redirect_to [@announcement.status_page, @announcement], alert: 'Failed to add update.'
    end
  end

  private

  def update_params
    params.require(:announcement_update).permit(:content, :status)
  end
end
