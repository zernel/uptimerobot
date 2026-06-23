class CheckResultsController < ApplicationController
  def index
    @monitor = Monitor.find(params[:monitor_id])
    @check_results = @monitor.check_results
                             .order(checked_at: :desc)
                             .page(params[:page])
  end
end
