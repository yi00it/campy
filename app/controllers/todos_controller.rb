class TodosController < ApplicationController
  before_action :set_project, only: [:new, :create]
  before_action :set_todo, only: [:show, :edit, :update, :destroy, :toggle_done]

  def show
    authorize_project!(@todo.project)
    @comment  = defined?(Comment) ? Comment.new : nil
    @comments = defined?(Comment) ? @todo.comments.order(created_at: :asc) : []
  end

  def new
    authorize_project!(@project)
    @todo = @project.todos.new
  end

  def create
    authorize_project!(@project)
    @todo = @project.todos.new(todo_params)
    if @todo.save
      redirect_to project_path(@project), notice: "Todo created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_project!(@todo.project)
  end

  def update
  authorize_project!(@todo.project)
  if @todo.update(todo_params)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @todo,
          partial: "todos/todo",
          locals: { todo: @todo }
        )
      end
      format.html { redirect_to @todo, notice: "Todo updated." }
    end
  else
    respond_to do |format|
      format.turbo_stream { render :edit, status: :unprocessable_entity }
      format.html         { render :edit, status: :unprocessable_entity }
    end
   end
  end

  def destroy
    project = @todo.project
    authorize_project!(project)
    @todo.destroy
    redirect_to project_path(project), notice: "Todo deleted."
  end

  # ---- Done/Undone toggle (Turbo) ----
  def toggle_done
    authorize_project!(@todo.project)

    # Flip the boolean and save; toggle! skips validations
    @todo.toggle!(:is_done)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @todo,                           # dom_id(@todo)
          partial: "todos/todo",
          locals: { todo: @todo }
        )
      end
      format.html do
        redirect_back fallback_location: project_path(@todo.project),
                      notice: (@todo.is_done ? "Marked as done." : "Marked as undone.")
      end
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_todo
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :description, :due_on, :is_done)
  end

  def authorize_project!(project)
    redirect_to projects_path, alert: "Not allowed." unless project.owner_id == current_user.id
  end
end
