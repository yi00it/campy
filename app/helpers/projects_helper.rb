module ProjectsHelper
  def gantt_total_days(start_date, end_date)
    [(end_date - start_date).to_i + 1, 1].max
  end

  def gantt_bar_style(project_start, project_end, activity)
    start_on = activity.start_on || project_start
    due_on = activity.due_on || start_on
    start_on = [start_on, project_start].max
    due_on = [due_on, project_end].min
    total_days = gantt_total_days(project_start, project_end)
    offset_days = (start_on - project_start).to_i
    span_days = [(due_on - start_on).to_i + 1, 1].max
    left_percent = (offset_days.to_f / total_days * 100).round(2)
    width_percent = (span_days.to_f / total_days * 100).round(2)
    "left: #{left_percent}%; width: #{width_percent}%;"
  end
end
