class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    @projects = Project.where(owner: current_user).order(created_at: :desc)
  end

def show
  authorize_owner!(@project)
  @todos = @project.todos.order(is_done: :asc, due_on: :asc, created_at: :desc)
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

  def edit
    authorize_owner!(@project)
  end

  def update
    authorize_owner!(@project)
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_owner!(@project)
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end

  def authorize_owner!(project)
    redirect_to projects_path, alert: "Not allowed." unless project.owner_id == current_user.id
  end
end
