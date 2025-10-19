class DisciplinesController < ApplicationController
  before_action :set_discipline, only: [:edit, :update, :destroy]

  def index
    @disciplines = Discipline.order(:name)
    @discipline = Discipline.new
  end

  def create
    @discipline = Discipline.new(discipline_params)
    if @discipline.save
      redirect_to disciplines_path, notice: "Discipline added."
    else
      @disciplines = Discipline.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @discipline.update(discipline_params)
      redirect_to disciplines_path, notice: "Discipline updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @discipline.destroy
    redirect_to disciplines_path, notice: "Discipline removed."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to disciplines_path, alert: "Cannot delete a discipline with activities."
  end

  private

  def set_discipline
    @discipline = Discipline.find(params[:id])
  end

  def discipline_params
    params.require(:discipline).permit(:name)
  end
end
