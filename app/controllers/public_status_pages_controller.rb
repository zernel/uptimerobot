class PublicStatusPagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :find_status_page
  before_action :check_password, if: -> { @status_page.password_digest.present? }

  def show
    @monitors = @status_page.monitors
                            .includes(:incidents)
                            .order(:name)
    @active_announcements = @status_page.announcements
                                        .where.not(status: 'resolved')
                                        .order(started_at: :desc)
    @resolved_announcements = @status_page.announcements
                                          .where(status: 'resolved')
                                          .order(resolved_at: :desc)
                                          .limit(10)
  end

  private

  def find_status_page
    @status_page = StatusPage.published.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.root.join('public', '404.html'), status: :not_found
  end

  def check_password
    return if session[:status_page_auth] == @status_page.id

    unless params[:password].present? &&
           ActiveSupport::SecurityUtils.secure_compare(
             params[:password],
             @status_page.password
           )
      render :password_form
    else
      session[:status_page_auth] = @status_page.id
    end
  end
end
