class AssignedActivitiesController < ApplicationController
  def index
    @activities = current_user.assigned_activities.includes(:project, :category).order(is_done: :asc, due_on: :asc, start_on: :asc)
  end
end
