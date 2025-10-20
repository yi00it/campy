class CalendarController < ApplicationController
  def show
    @current_date = parsed_date || Date.current
    @calendar_range = build_calendar_range(@current_date)
    @activities = load_assigned_activities(@calendar_range)
    @events = current_user.calendar_events.for_range(@calendar_range)
    @entries_by_day = build_entries(@calendar_range, @activities, @events)
  end

  private

  def parsed_date
    return unless params[:month].present?

    Date.parse(params[:month])
  rescue ArgumentError
    nil
  end

  def build_calendar_range(date)
    start_date = date.beginning_of_month.beginning_of_week(:monday)
    end_date = date.end_of_month.end_of_week(:monday)
    start_date..end_date
  end

  def load_assigned_activities(range)
    current_user.assigned_activities
                .where("activities.start_on <= ? AND activities.due_on >= ?", range.end, range.begin)
                .includes(:project, :zone, :discipline)
  end

  def build_entries(range, activities, events)
    grouped = Hash.new { |hash, key| hash[key] = [] }

    activities.each do |activity|
      next if activity.start_on.blank? || activity.due_on.blank?

      start_date = [activity.start_on, range.begin].max
      end_date = [activity.due_on, range.end].min

      (start_date..end_date).each do |date|
        grouped[date] << {
          category: :activity,
          activity:,
          multi_day: activity.start_on != activity.due_on,
          all_day: true,
          sort_key: activity.start_on.beginning_of_day
        }
      end
    end

    events.each do |event|
      event_start = event.start_at.to_date
      event_end = event.end_at.to_date
      event_range = event_start..event_end
      event_range.each do |date|
        next unless range.cover?(date)

        grouped[date] << {
          category: :calendar_event,
          calendar_event: event,
          multi_day: event_start != event_end,
          all_day: event.all_day?,
          sort_key: event.start_at
        }
      end
    end

    grouped
  end
end
