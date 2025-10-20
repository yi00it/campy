class ActivitiesController < ApplicationController
  REACTION_EMOJIS = ["👍", "🎉", "❤️", "👏"].freeze

  before_action :set_project, only: [:new, :create]
  before_action :set_activity, only: [:show, :edit, :update, :destroy, :toggle_done]
  before_action :set_activity_options, only: [:new, :create, :edit, :update]
  before_action :set_assignable_users, only: [:new, :create, :edit, :update]

  def show
    return unless authorize_project!(@activity.project, ability: :read)

    @update  = Comment.new
    @updates = @activity.comments.roots
                           .includes(:author, :comment_reactions, replies: [:author, :comment_reactions])
                           .with_attached_files
                           .order(created_at: :desc)
    @reaction_emojis = REACTION_EMOJIS
  end

  def new
    return unless authorize_project!(@project, ability: :manage)

    @activity = @project.activities.new
  end

  def create
    return unless authorize_project!(@project, ability: :manage)

    @activity = @project.activities.new(activity_params)
    if @activity.save
      # Notify assignee if assigned during creation
      if @activity.assignee.present?
        NotificationService.notify_activity_assigned(@activity, current_user)
      end
      redirect_to project_path(@project), notice: "Activity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return unless authorize_project!(@activity.project, ability: :manage)
  end

  def update
    return unless authorize_project!(@activity.project, ability: :manage)

    # Track if assignee changed
    assignee_changed = @activity.will_save_change_to_assignee_id?
    old_assignee_id = @activity.assignee_id

    if @activity.update(activity_params)
      # Send appropriate notification
      if assignee_changed && @activity.assignee.present? && @activity.assignee_id != current_user.id
        NotificationService.notify_activity_assigned(@activity, current_user)
      elsif !assignee_changed
        NotificationService.notify_activity_updated(@activity, current_user)
      end

      respond_to do |format|
        format.html { redirect_to @activity, notice: "Activity updated." }
        format.json { render json: { success: true, activity: @activity }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @activity.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    project = @activity.project
    return unless authorize_project!(project, ability: :manage)

    @activity.destroy
    redirect_to project_path(project), notice: "Activity deleted."
  end

  def toggle_done
    return unless authorize_project!(@activity.project, ability: :update_status, activity: @activity)

    @activity.toggle!(:is_done)
    @project = @activity.project
    scoped = @project.activities.includes(:assignee, :discipline, :zone).order(start_on: :asc, due_on: :asc, created_at: :desc)
    @active_activities = scoped.where(is_done: false)
    @completed_activities = scoped.where(is_done: true)
    @active_count = @active_activities.count
    @completed_count = @completed_activities.count

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
    params.require(:activity).permit(:title, :description, :start_on, :due_on, :is_done, :discipline_id, :zone_id, :assignee_id, files: [])
  end

  def set_activity_options
    @disciplines = Discipline.order(:name)
    @zones = Zone.order(:name)
  end

  def set_assignable_users
    project = @project || @activity&.project
    @assignable_users = project ? project.assignable_members : []
  end

  def authorize_project!(project, ability: :read, activity: nil)
    allowed = case ability
              when :read
                project.accessible_by?(current_user)
              when :manage
                can_manage_project?(project)
              when :update_status
                can_manage_project?(project) ||
                  (project_role(project) == :subcontractor && activity&.assignee_id == current_user.id)
              else
                false
              end

    return true if allowed

    redirect_to projects_path, alert: "Not allowed."
    false
  end
end
