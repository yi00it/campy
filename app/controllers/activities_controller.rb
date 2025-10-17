class ActivitiesController < ApplicationController
  REACTION_EMOJIS = ["👍", "🎉", "❤️", "👏"].freeze

  before_action :set_project, only: [:new, :create]
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :toggle_done]
  before_action :set_categories, only: [:new, :create, :edit, :update]
  before_action :set_assignable_users, only: [:new, :create, :edit, :update]

  def show
    return unless authorize_project!(@activity.project)

    if defined?(Comment)
      @update  = Comment.new
      @updates = @activity.comments.includes(:comment_reactions).with_attached_files.order(created_at: :desc)
      @reaction_emojis = REACTION_EMOJIS
    else
      @update  = nil
      @updates = []
    end
  end

  def new
    return unless authorize_project!(@project)

    @activity = @project.activities.new
  end

  def create
    return unless authorize_project!(@project)

    @activity = @project.activities.new(activity_params)
    if @activity.save
      redirect_to project_path(@project), notice: "Activity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return unless authorize_project!(@activity.project)
  end

  def update
    return unless authorize_project!(@activity.project)

    if @activity.update(activity_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @activity,
            partial: "activities/activity",
            locals: { activity: @activity }
          )
        end
        format.html { redirect_to @activity, notice: "Activity updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html         { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    project = @activity.project
    return unless authorize_project!(project)

    @activity.destroy
    redirect_to project_path(project), notice: "Activity deleted."
  end

  def toggle_done
    return unless authorize_project!(@activity.project)

    @activity.toggle!(:is_done)
    @project = @activity.project
    @project.reload
    scoped = @project.activities.order(start_on: :asc, due_on: :asc, created_at: :desc)
    @active_activities = scoped.where(is_done: false)
    @completed_activities = scoped.where(is_done: true)
    @active_count = @active_activities.size
    @completed_count = @completed_activities.size

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_back fallback_location: project_path(@activity.project),
                      notice: (@activity.is_done ? "Marked as done." : "Marked as undone.")
      end
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_activity
    @activity = Activity.find(params[:id])
    @project = @activity.project
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :start_on, :due_on, :is_done, :category_id, :assignee_id, files: [])
  end

  def set_categories
    @categories = Category.order(:name)
  end

  def set_assignable_users
    project = @project || @activity&.project
    @assignable_users = project ? project.team_members : []
  end

  def authorize_project!(project)
    return true if project.accessible_by?(current_user)

    redirect_to projects_path, alert: "Not allowed."
    false
  end
end
