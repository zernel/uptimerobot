class IncidentCommentsController < ApplicationController
  def create
    @incident = Incident.find(params[:incident_id])
    @comment = @incident.incident_comments.build(comment_params)

    if @comment.save
      redirect_to @incident, notice: 'Comment added.'
    else
      redirect_to @incident, alert: 'Failed to add comment.'
    end
  end

  private

  def comment_params
    params.require(:incident_comment).permit(:content)
  end
end
