class DashboardsController < ApplicationController
  def show
    @projects = recent_projects
    @assigned_activities = current_user.assigned_activities.includes(:project, :discipline, :zone).order(due_on: :asc).limit(5)
    @upcoming_events = current_user.calendar_events.where("start_at >= ?", Time.current.beginning_of_day).order(:start_at).limit(5)
    @activity_stats = activity_stats
    @project_stats = project_stats
  end

  private

  def recent_projects
    Project.accessible_to(current_user)
           .includes(:owner)
           .order(updated_at: :desc)
           .limit(5)
  end

  def activity_stats
    scoped = current_user.assigned_activities
    total = scoped.count
    done = scoped.where(is_done: true).count
    overdue = scoped.where("due_on < ? AND is_done = ?", Date.current, false).count
    upcoming = scoped.where("due_on BETWEEN ? AND ?", Date.current, Date.current + 7.days).count

    {
      total:,
      done:,
      overdue:,
      upcoming:,
      done_pct: total.positive? ? ((done.to_f / total) * 100).round : 0,
      overdue_pct: total.positive? ? ((overdue.to_f / total) * 100).round : 0
    }
  end

  def project_stats
    accessible = Project.accessible_to(current_user)
    {
      total: accessible.count,
      owned: accessible.where(owner_id: current_user.id).count,
      active: accessible.joins(:activities).merge(Activity.where(is_done: false)).distinct.count
    }
  end
end
