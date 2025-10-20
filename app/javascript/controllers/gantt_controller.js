import { Controller } from "@hotwired/stimulus"
import dayjs from "dayjs"

export default class extends Controller {
  static targets = ["canvas", "wrapper", "fullscreenButton"]
  static values = {
    start: String,
    end: String,
    projectId: Number,
    activities: Array,
  }

  connect() {
    this.render()
  }

  render() {
    const canvas = this.canvasTarget
    if (!canvas || !this.startValue || !this.endValue) return

    const timelineStart = dayjs(this.startValue).startOf("day")
    const timelineEnd = dayjs(this.endValue).startOf("day")
    const today = dayjs().startOf("day")

    // Build array of all days
    const days = []
    let cursor = timelineStart.clone()
    while (cursor.isBefore(timelineEnd, "day") || cursor.isSame(timelineEnd, "day")) {
      days.push(cursor.clone())
      cursor = cursor.add(1, "day")
    }

    // Find today's column index
    const todayIndex = days.findIndex(d => d.isSame(today, "day"))

    // Parse activities
    const activities = this.activitiesValue.map(a => ({
      ...a,
      start: dayjs(a.start_on).startOf("day"),
      end: dayjs(a.due_on).startOf("day")
    }))

    canvas.innerHTML = ""
    this.renderHeader(canvas, days, todayIndex)
    activities.forEach(activity => {
      this.renderActivityRow(canvas, activity, days, todayIndex)
    })
  }

  renderHeader(container, days, todayIndex) {
    const header = document.createElement("div")
    header.className = "gantt__header"

    // Activity label column
    const labelCell = document.createElement("div")
    labelCell.className = "gantt__label"
    labelCell.textContent = "Activity"
    header.appendChild(labelCell)

    // Timeline wrapper (not using grid here, just a container)
    const timeline = document.createElement("div")
    timeline.className = "gantt__timeline"
    timeline.style.position = "relative"

    // Month row - group days by month
    const monthRow = document.createElement("div")
    monthRow.className = "gantt__month-row"
    monthRow.style.display = "flex"

    let currentMonth = null
    let monthStart = 0

    days.forEach((day, index) => {
      const monthLabel = day.format("MMM YYYY")
      if (monthLabel !== currentMonth) {
        if (currentMonth !== null) {
          const cell = document.createElement("div")
          cell.className = "gantt__month-cell"
          cell.style.width = ((index - monthStart) * 60) + "px"
          cell.textContent = currentMonth
          monthRow.appendChild(cell)
        }
        currentMonth = monthLabel
        monthStart = index
      }
    })

    // Last month
    if (currentMonth !== null) {
      const cell = document.createElement("div")
      cell.className = "gantt__month-cell"
      cell.style.width = ((days.length - monthStart) * 60) + "px"
      cell.textContent = currentMonth
      monthRow.appendChild(cell)
    }

    timeline.appendChild(monthRow)

    // Day row - show each day
    const dayRow = document.createElement("div")
    dayRow.className = "gantt__week-row"
    dayRow.style.display = "flex"

    days.forEach((day, index) => {
      const cell = document.createElement("div")
      const isWeekend = [0, 6].includes(day.day())
      cell.className = "gantt__timeline-cell" + (isWeekend ? " gantt__timeline-cell--weekend" : "")
      cell.style.width = "60px"
      cell.textContent = day.format("DD")
      dayRow.appendChild(cell)
    })

    timeline.appendChild(dayRow)

    // Today line
    if (todayIndex >= 0) {
      const todayLine = document.createElement("div")
      todayLine.style.position = "absolute"
      todayLine.style.top = "0"
      todayLine.style.bottom = "0"
      todayLine.style.left = (todayIndex * 60) + "px"
      todayLine.style.width = "2px"
      todayLine.style.background = "var(--color-error)"
      todayLine.style.zIndex = "100"

      const label = document.createElement("span")
      label.style.position = "absolute"
      label.style.top = "0"
      label.style.left = "4px"
      label.style.fontSize = "11px"
      label.style.background = "var(--color-error)"
      label.style.color = "white"
      label.style.padding = "2px 6px"
      label.style.borderRadius = "3px"
      label.style.whiteSpace = "nowrap"
      label.textContent = "Today"
      todayLine.appendChild(label)

      timeline.appendChild(todayLine)
    }

    header.appendChild(timeline)
    container.appendChild(header)
  }

  renderActivityRow(container, activity, days, todayIndex) {
    const row = document.createElement("div")
    row.className = "gantt__row"

    // Activity name
    const labelCell = document.createElement("div")
    labelCell.className = "gantt__row-label"

    const link = document.createElement("a")
    link.href = activity.url || "#"
    link.className = "gantt__row-title"
    link.textContent = activity.title
    labelCell.appendChild(link)

    row.appendChild(labelCell)

    // Timeline
    const timelineCell = document.createElement("div")
    timelineCell.className = "gantt__row-timeline"
    timelineCell.style.position = "relative"

    // Grid background
    const grid = document.createElement("div")
    grid.className = "gantt__grid"
    grid.style.display = "grid"
    grid.style.gridTemplateColumns = days.map(() => "60px").join(" ")
    grid.style.height = "100%"

    // Grid cells
    days.forEach((day) => {
      const cell = document.createElement("div")
      const isWeekend = [0, 6].includes(day.day())
      cell.className = "gantt__grid-cell" + (isWeekend ? " gantt__grid-cell--weekend" : "")
      grid.appendChild(cell)
    })

    timelineCell.appendChild(grid)

    // Today line
    if (todayIndex >= 0) {
      const todayLine = document.createElement("div")
      todayLine.style.position = "absolute"
      todayLine.style.top = "0"
      todayLine.style.bottom = "0"
      todayLine.style.left = (todayIndex * 60) + "px"
      todayLine.style.width = "2px"
      todayLine.style.background = "var(--color-error)"
      todayLine.style.opacity = "0.6"
      todayLine.style.zIndex = "5"
      timelineCell.appendChild(todayLine)
    }

    // Activity bar
    const startIndex = days.findIndex(d => d.isSame(activity.start, "day"))
    const endIndex = days.findIndex(d => d.isSame(activity.end, "day"))

    if (startIndex >= 0 && endIndex >= 0 && endIndex >= startIndex) {
      const bar = document.createElement("div")
      bar.className = "gantt__bar gantt__bar--" + activity.status
      bar.style.position = "absolute"
      bar.style.top = "50%"
      bar.style.transform = "translateY(-50%)"
      bar.style.left = (startIndex * 60) + "px"
      bar.style.width = ((endIndex - startIndex + 1) * 60) + "px"
      bar.style.height = "28px"
      bar.style.zIndex = "10"
      bar.style.cursor = "pointer"
      bar.style.borderRadius = "4px"

      bar.addEventListener("mouseenter", (e) => this.showTooltip(e, activity))
      bar.addEventListener("mouseleave", () => this.removeTooltip())
      bar.addEventListener("click", () => {
        if (activity.url) window.location.href = activity.url
      })

      timelineCell.appendChild(bar)
    }

    row.appendChild(timelineCell)
    container.appendChild(row)
  }

  toggleFullscreen(event) {
    event.preventDefault()
    const wrapper = this.wrapperTarget
    if (!wrapper) return

    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      wrapper.requestFullscreen().catch(err => console.log(err))
    }
  }

  showTooltip(event, activity) {
    this.removeTooltip()

    const tooltip = document.createElement("div")
    tooltip.className = "gantt__tooltip"
    tooltip.innerHTML = `
      <div class="gantt__tooltip-title">${activity.title}</div>
      <div class="gantt__tooltip-row"><strong>Start</strong><span>${activity.start_label}</span></div>
      <div class="gantt__tooltip-row"><strong>Finish</strong><span>${activity.due_label}</span></div>
      ${activity.duration_days ? `<div class="gantt__tooltip-row"><strong>Duration</strong><span>${activity.duration_days} days</span></div>` : ''}
      ${activity.assignee ? `<div class="gantt__tooltip-row"><strong>Assignee</strong><span>${activity.assignee}</span></div>` : ''}
    `

    document.body.appendChild(tooltip)
    this.currentTooltip = tooltip

    const rect = event.target.getBoundingClientRect()
    const tooltipRect = tooltip.getBoundingClientRect()

    let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2)
    let top = rect.top - tooltipRect.height - 8

    if (left < 10) left = 10
    if (left + tooltipRect.width > window.innerWidth - 10) {
      left = window.innerWidth - tooltipRect.width - 10
    }
    if (top < 10) top = rect.bottom + 8

    tooltip.style.left = left + "px"
    tooltip.style.top = top + "px"
  }

  removeTooltip() {
    if (this.currentTooltip) {
      this.currentTooltip.remove()
      this.currentTooltip = null
    }
  }
}
