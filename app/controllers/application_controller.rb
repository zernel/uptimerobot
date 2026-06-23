class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_admin?

  private

  def current_admin?
    current_user&.admin?
  end
end
