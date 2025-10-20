module ProjectsHelper
  def gantt_total_days(start_date, end_date)
    [(end_date - start_date).to_i + 1, 1].max
  end

  def gantt_time_scale(start_date, end_date, total_width: 1600)
    total_days = gantt_total_days(start_date, end_date)

    if total_days <= 90
      { step: :day, column_width: 60 }
    elsif total_days <= 365 && total_days * 72 <= total_width
      { step: :week, column_width: 72 }
    else
      months_count = ((end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month) + 1)
      column_width = (total_width.to_f / months_count).floor
      column_width = 100 if column_width < 100
      { step: :month, column_width: column_width }
    end
  end

  def gantt_timeline_units(start_date, end_date, total_width: 1600)
    scale = gantt_time_scale(start_date, end_date, total_width: total_width)

    case scale[:step]
    when :day
      (start_date..end_date).map do |date|
        {
          label: date.strftime("%d %b %Y"),
          start: date,
          end: date,
          weekend: date.saturday? || date.sunday?
        }
      end
    when :week
      units = []
      month_cursor = start_date.beginning_of_month

      while month_cursor <= end_date
        month_start = [month_cursor, start_date].max
        month_end = [month_cursor.end_of_month, end_date].min
        week_index = 1
        pointer = month_start
        month_label = month_cursor.strftime("%b-%y")

        while pointer <= month_end
          unit_start = pointer
          unit_end = [pointer + 6.days, month_end].min
          week_label = "W#{week_index}"
          units << {
            month_label: month_label,
            label: week_label,
            start: unit_start,
            end: unit_end,
            weekend: false
          }
          pointer = unit_end + 1.day
          week_index += 1
        end

        month_cursor = month_cursor.next_month.beginning_of_month
      end

      units
    when :month
      current = start_date.beginning_of_month
      units = []
      while current <= end_date
        unit_start = [current, start_date].max
        unit_end = [current.end_of_month, end_date].min
        label = current.strftime("%b %Y")
        units << { label:, month_label: label, start: unit_start, end: unit_end, weekend: false }
        current = current.next_month
      end
      units
    else
      []
    end
  end

  def gantt_data_date_offset(start_date, end_date, scale:, units:, date: Date.current)
    return nil if date < start_date || date > end_date

    case scale[:step]
    when :month
      return 0 if units.empty?
      target_index = units.index { |unit| date <= unit[:end] } || units.size - 1
      unit = units[target_index]
      unit_span = (unit[:end] - unit[:start]).to_f
      fraction = if unit_span.negative? || unit_span.zero?
                   0
                 else
                   ((date - unit[:start]).to_f / unit_span).clamp(0, 1)
                 end
      (((target_index + fraction) / units.size) * 100).round(2)
    else
      total_span = (end_date - start_date).to_f
      return 0 if total_span.zero?
      (((date - start_date).to_f / total_span) * 100).clamp(0, 100).round(2)
    end
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

  def activity_status(activity)
    if activity.is_done?
      :done
    elsif activity.start_on.present? && activity.start_on > Date.current
      :planned
    else
      :in_progress
    end
  end

  def gantt_bar_class(activity)
    case activity_status(activity)
    when :done
      "gantt__bar--done"
    when :planned
      "gantt__bar--planned"
    else
      "gantt__bar--in-progress"
    end
  end
end
