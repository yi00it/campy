require Rails.root.join("app/services/reports/gantt_pdf")

class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :gantt, :edit, :update, :destroy]
  before_action :authorize_project_member!, only: [:show, :gantt]
  before_action :authorize_project_owner!, only: [:edit, :update, :destroy]

  def index
    @projects = Project.left_outer_joins(:project_memberships)
                       .where("projects.owner_id = :user_id OR project_memberships.user_id = :user_id", user_id: current_user.id)
                       .distinct
                       .order(created_at: :desc)
  end

  def show
    scoped = @project.activities.includes(:assignee, :discipline, :zone).order(start_on: :asc, due_on: :asc, created_at: :desc)
    @active_activities = scoped.where(is_done: false)
    @completed_activities = scoped.where(is_done: true)
    @active_count = @active_activities.count
    @completed_count = @completed_activities.count
    @project_memberships = @project.project_memberships.includes(:user)
    @membership = @project.project_memberships.new
  end

  def new
    @project = Project.new
  end

  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  def gantt
    @activities = @project.activities.includes(:assignee, :discipline, :zone).order(start_on: :asc, due_on: :asc, created_at: :asc)
    if @activities.any?
      @timeline_start = @activities.map(&:start_on).compact.min || Date.current
      @timeline_end = @activities.map(&:due_on).compact.max || @timeline_start
      @timeline_end = @timeline_start if @timeline_end < @timeline_start
    else
      @timeline_start = Date.current
      @timeline_end = @timeline_start
    end

    respond_to do |format|
      format.html
      format.pdf do
        pdf = Reports::GanttPdf.new(@project, @activities, @timeline_start, @timeline_end).render
        send_data pdf,
                  filename: "#{@project.name.parameterize}-gantt.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end


  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end

  def authorize_project_owner!
    return if @project.owner_id == current_user.id

    redirect_to projects_path, alert: "Not allowed."
    false
  end

  def authorize_project_member!
    return if @project.accessible_by?(current_user)

    redirect_to projects_path, alert: "Not allowed."
    false
  end
end
