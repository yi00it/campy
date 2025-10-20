module CalendarHelper
  def calendar_weeks(range)
    range.each_slice(7)
  end

  def day_classes(date, current_month)
    classes = ["calendar__day"]
    classes << "calendar__day--other-month" if date.month != current_month.month
    classes << "calendar__day--today" if date == Date.current
    classes.join(" ")
  end

  def day_heading(date)
    date.strftime("%a %d")
  end

  def format_time(time)
    time&.strftime("%H:%M")
  end
end
