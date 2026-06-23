class CheckResultsController < ApplicationController
  def index
    @monitor = SiteMonitor.find(params[:monitor_id])
    @check_results = @monitor.check_results
                             .order(checked_at: :desc)
                             .page(params[:page])
  end
end
