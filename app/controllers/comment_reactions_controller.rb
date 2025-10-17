class CommentReactionsController < ApplicationController
  before_action :set_comment
  before_action :authorize_comment!

  def create
    @emoji = params.require(:emoji)
    @reaction_emojis = ActivitiesController::REACTION_EMOJIS
    reaction = @comment.comment_reactions.find_by(user: current_user, emoji: @emoji)

    if reaction
      reaction.destroy
    else
      @comment.comment_reactions.create(user: current_user, emoji: @emoji)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: activity_path(@comment.activity) }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:comment_id])
    @activity = @comment.activity
    @project = @activity.project
  end

  def authorize_comment!
    return if @project.accessible_by?(current_user)

    redirect_to projects_path, alert: "Not allowed."
  end
end
