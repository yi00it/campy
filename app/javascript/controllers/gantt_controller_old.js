import { Controller } from "@hotwired/stimulus"
import dayjs from "dayjs"

export default class extends Controller {
  static targets = ["canvas", "scaleButton", "wrapper", "fullscreenButton"]
  static values = {
    start: String,
    end: String,
    scale: { type: String, default: "auto" },
    projectId: Number,
    activities: Array,
  }

  connect() {
    this.draggingActivity = null
    this.dragStartX = 0
    this.dragStartOffset = 0
    this.handleResize = this.render.bind(this)
    this.resizeObserver = new ResizeObserver(this.handleResize)
    this.resizeObserver.observe(this.canvasTarget || this.element)
    document.addEventListener("fullscreenchange", this.updateFullscreenState)
    document.addEventListener("webkitfullscreenchange", this.updateFullscreenState)
    this.render()
    this.updateActiveButtons()
    this.updateFullscreenState()
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
    this.removeTooltip()
    document.removeEventListener("fullscreenchange", this.updateFullscreenState)
    document.removeEventListener("webkitfullscreenchange", this.updateFullscreenState)
    document.body.classList.remove("has-gantt-fullscreen")
  }

  render() {
    if (!this.hasStartValue || !this.hasEndValue) return
    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element
    if (!canvas) return

    const start = dayjs(this.startValue)
    const end = dayjs(this.endValue)
    if (!start.isValid() || !end.isValid()) return

    const width = canvas.clientWidth || this.element.clientWidth || 1600

    const activities = (this.activitiesValue || []).map((activity) => ({
      ...activity,
      start: activity.start_on ? dayjs(activity.start_on) : null,
      end: activity.due_on ? dayjs(activity.due_on) : null,
    }))

    const scale = this.determineScale(start, end, width)
    const units = this.computeUnits(start, end, scale)
    const dataDateOffset = this.computeDataDateOffset(start, end, scale, units)

    canvas.innerHTML = ""
    this.buildHeader(canvas, units, scale, dataDateOffset)
    activities.forEach((activity, index) => {
      this.buildRow(canvas, activity, index, units, scale, dataDateOffset)
    })
  }

  determineScale(start, end, width) {
    switch (this.scaleValue) {
      case "day":
        return { step: "day", columnWidth: 60 }
      case "week":
        return { step: "week", columnWidth: 72 }
      case "month":
        return { step: "month", columnWidth: Math.max(Math.floor(width / this.monthSpan(start, end)), 100) }
      default:
        return this.computeScale(start, end, width)
    }
  }

  setScale(event) {
    event.preventDefault()
    const step = event.currentTarget.dataset.ganttScaleStep || "auto"
    this.scaleValue = step
    this.updateActiveButtons()
    this.render()
  }

  updateActiveButtons() {
    if (!this.hasScaleButtonTarget) return
    this.scaleButtonTargets.forEach((button) => {
      const step = button.dataset.ganttScaleStep || "auto"
      button.classList.toggle("gantt__toolbar-button--active", step === this.scaleValue)
    })
  }

  wrapperElement() {
    return this.hasWrapperTarget ? this.wrapperTarget : this.element
  }

  fullscreenSupported() {
    const wrapper = this.wrapperElement()
    if (!wrapper) return false
    return Boolean(wrapper.requestFullscreen || wrapper.webkitRequestFullscreen)
  }

  isFullscreen() {
    const wrapper = this.wrapperElement()
    if (!wrapper) return false
    const doc = document
    const fullscreenElement = doc.fullscreenElement || doc.webkitFullscreenElement
    return fullscreenElement === wrapper || wrapper.classList.contains("gantt-wrapper--fullscreen")
  }

  updateFullscreenButton(isActive) {
    if (!this.hasFullscreenButtonTarget) return
    this.fullscreenButtonTarget.textContent = isActive ? "Exit full screen" : "Full screen"
    this.fullscreenButtonTarget.setAttribute("aria-pressed", isActive)
  }

  updateFullscreenState = () => {
    const wrapper = this.wrapperElement()
    if (!wrapper) return
    const isActive = this.isFullscreen()
    wrapper.classList.toggle("gantt-wrapper--fullscreen", isActive)
    document.body.classList.toggle("has-gantt-fullscreen", isActive)
    this.updateFullscreenButton(isActive)
  }

  toggleFullscreen(event) {
    event.preventDefault()
    const wrapper = this.wrapperElement()
    if (!wrapper) return

    if (!this.fullscreenSupported()) {
      const isActive = !wrapper.classList.contains("gantt-wrapper--fullscreen")
      wrapper.classList.toggle("gantt-wrapper--fullscreen", isActive)
      document.body.classList.toggle("has-gantt-fullscreen", isActive)
      this.updateFullscreenButton(isActive)
      return
    }

    if (this.isFullscreen()) {
      const exit = document.exitFullscreen?.bind(document) || document.webkitExitFullscreen?.bind(document)
      exit?.().finally(() => this.updateFullscreenState())
    } else {
      const request = wrapper.requestFullscreen?.bind(wrapper) || wrapper.webkitRequestFullscreen?.bind(wrapper)
      request?.().catch(() => this.updateFullscreenState())
    }
  }

  computeScale(start, end, width) {
    const totalDays = end.diff(start, "day") + 1

    if (totalDays <= 90) {
      return { step: "day", columnWidth: 60 }
    }

    const weeks = Math.ceil(totalDays / 7)
    if (totalDays <= 365 && weeks * 72 <= width) {
      return { step: "week", columnWidth: 72 }
    }

    const months = this.monthSpan(start, end)
    const columnWidth = Math.max(Math.floor(width / months), 100)
    return { step: "month", columnWidth }
  }

  computeUnits(start, end, scale) {
    switch (scale.step) {
      case "day":
        return this.buildDailyUnits(start, end)
      case "week":
        return this.buildWeeklyUnits(start, end)
      case "month":
      default:
        return this.buildMonthlyUnits(start, end)
    }
  }

  monthSpan(start, end) {
    return end.year() * 12 + end.month() - (start.year() * 12 + start.month()) + 1
  }

  buildDailyUnits(start, end) {
    const units = []
    let cursor = start.clone()
    while (this.isOnOrBefore(cursor, end, "day")) {
      units.push({
        label: cursor.format("DD MMM YYYY"),
        month_label: cursor.format("MMM-YY"),
        start: cursor.clone(),
        end: cursor.clone(),
        weekend: [0, 6].includes(cursor.day()),
        span: 1,
      })
      cursor = cursor.add(1, "day")
    }
    return units
  }

  buildWeeklyUnits(start, end) {
    const units = []
    const timelineStart = start.clone().startOf("day")
    const timelineEnd = end.clone().startOf("day")
    const dayOfWeek = timelineStart.day() // Sunday = 0
    const offsetToMonday = (dayOfWeek + 6) % 7
    let cursor = timelineStart.clone().subtract(offsetToMonday, "day")

    while (this.isOnOrBefore(cursor, timelineEnd, "day")) {
      const unitStart = cursor.isBefore(timelineStart, "day") ? timelineStart.clone() : cursor.clone()
      const candidateEnd = cursor.clone().add(6, "day")
      const unitEnd = candidateEnd.isAfter(timelineEnd, "day") ? timelineEnd.clone() : candidateEnd
      const spanDays = unitEnd.diff(unitStart, "day") + 1

      units.push({
        label: unitStart.format("DD MMM"),
        month_label: unitStart.format("MMM-YY"),
        start: unitStart,
        end: unitEnd,
        weekend: false,
        span: spanDays,
      })

      cursor = cursor.add(1, "week")
    }

    return units
  }

  buildMonthlyUnits(start, end) {
    const units = []
    let cursor = start.clone().startOf("month")
    while (this.isOnOrBefore(cursor, end, "month")) {
      const unitStart = cursor.isBefore(start) ? start.clone() : cursor.clone()
      const unitEnd = cursor.clone().endOf("month")
      const boundedEnd = unitEnd.isAfter(end) ? end.clone() : unitEnd
      const spanDays = boundedEnd.diff(unitStart, "day") + 1

      units.push({
        label: cursor.format("MMM YYYY"),
        month_label: cursor.format("MMM YYYY"),
        start: unitStart,
        end: boundedEnd,
        weekend: false,
        span: spanDays,
      })
      cursor = cursor.add(1, "month")
    }
    return units
  }

  computeDataDateOffset(start, end, scale, units) {
    if (units.length === 0) return null
    const today = dayjs().startOf("day")
    const firstUnitStart = units[0].start.clone().startOf("day")
    const lastUnitEnd = units[units.length - 1].end.clone().startOf("day")

    if (today.isBefore(firstUnitStart, "day") || today.isAfter(lastUnitEnd, "day")) {
      return null
    }

    // Find which column contains today
    for (let i = 0; i < units.length; i++) {
      const unit = units[i]
      const unitStart = unit.start.clone().startOf("day")
      const unitEnd = unit.end.clone().startOf("day")

      if ((today.isSame(unitStart, "day") || today.isAfter(unitStart, "day")) &&
          (today.isSame(unitEnd, "day") || today.isBefore(unitEnd, "day"))) {
        return {
          gridColumn: `${i + 1} / ${i + 2}` // Span the column containing today
        }
      }
    }

    return null
  }

  buildHeader(container, units, scale, dataDateOffset) {
    const header = document.createElement("div")
    header.className = "gantt__header"

    const labelCell = document.createElement("div")
    labelCell.className = "gantt__label"
    labelCell.textContent = "Activity"
    header.appendChild(labelCell)

    const timeline = document.createElement("div")
    timeline.className = "gantt__timeline"
    const columnTemplate = this.gridTemplateColumnsForUnits(units, scale.columnWidth)
    timeline.style.gridTemplateColumns = columnTemplate

    const monthRow = document.createElement("div")
    monthRow.className = "gantt__month-row"
    monthRow.style.gridTemplateColumns = columnTemplate

    this.groupByMonth(units).forEach((group) => {
      const cell = document.createElement("div")
      cell.className = "gantt__month-cell"
      cell.style.gridColumn = "span " + group.span
      cell.textContent = group.label
      monthRow.appendChild(cell)
    })

    timeline.appendChild(monthRow)

    if (scale.step !== "month") {
      const weekRow = document.createElement("div")
      weekRow.className = "gantt__week-row"
      weekRow.style.gridTemplateColumns = columnTemplate

      units.forEach((unit) => {
        const cell = document.createElement("div")
        cell.className = "gantt__timeline-cell" + (unit.weekend ? " gantt__timeline-cell--weekend" : "")
        cell.textContent = unit.label
        weekRow.appendChild(cell)
      })

      timeline.appendChild(weekRow)
    }

    if (dataDateOffset !== null) {
      const dataLine = document.createElement("div")
      dataLine.className = "gantt__data-date-line gantt__data-date-line--header"
      dataLine.style.gridColumn = dataDateOffset.gridColumn

      const label = document.createElement("span")
      label.className = "gantt__data-date-label"
      label.textContent = "Today · " + dayjs().format("DD MMM YYYY")
      dataLine.appendChild(label)
      timeline.appendChild(dataLine)
    }

    header.appendChild(timeline)
    container.appendChild(header)
  }

  buildRow(container, activity, index, units, scale, dataDateOffset) {
    const row = document.createElement("div")
    row.className = "gantt__row"

    const labelCell = document.createElement("div")
    labelCell.className = "gantt__row-label"

    const titleLink = document.createElement("a")
    titleLink.href = activity.url || "#"
    titleLink.className = "gantt__row-title"
    titleLink.textContent = activity.title
    labelCell.appendChild(titleLink)

    row.appendChild(labelCell)

    const barsCell = document.createElement("div")
    barsCell.className = "gantt__row-timeline"

    const grid = document.createElement("div")
    grid.className = "gantt__grid"
    const columnTemplate = this.gridTemplateColumnsForUnits(units, scale.columnWidth)
    grid.style.gridTemplateColumns = columnTemplate

    units.forEach((unit) => {
      const cell = document.createElement("div")
      cell.className = "gantt__grid-cell" + (unit.weekend ? " gantt__grid-cell--weekend" : "")
      grid.appendChild(cell)
    })

    if (dataDateOffset !== null) {
      const dataLine = document.createElement("div")
      dataLine.className = "gantt__data-date"
      dataLine.style.gridColumn = dataDateOffset.gridColumn
      grid.appendChild(dataLine)
    }

    // Add the bar to the grid
    const barContainer = document.createElement("div")
    barContainer.className = "gantt__bar-container"
    const gridPosition = this.barGridPosition(activity, units)
    barContainer.style.gridColumn = gridPosition.gridColumn

    const timelineStart = units[0]?.start?.clone().startOf("day") || dayjs().startOf("day")
    const timelineEnd = units[units.length - 1]?.end?.clone().startOf("day") || timelineStart.clone()

    const bar = document.createElement("div")
    bar.className = "gantt__bar gantt__bar--" + activity.status
    bar.dataset.activityId = activity.id
    bar.style.cursor = "pointer"

    // Add tooltip and click handlers
    bar.addEventListener("mouseenter", (e) => this.showTooltip(e, activity))
    bar.addEventListener("mouseleave", () => this.removeTooltip())
    bar.addEventListener("click", () => {
      if (activity.url) {
        window.location.href = activity.url
      }
    })

    // Add drag handlers for rescheduling
    bar.addEventListener("mousedown", (e) => this.startDrag(e, activity, bar, timelineStart, timelineEnd))

    barContainer.appendChild(bar)
    grid.appendChild(barContainer)

    barsCell.appendChild(grid)
    row.appendChild(barsCell)
    container.appendChild(row)
  }

  statusClass(status) {
    switch (status) {
      case "done":
        return "gantt__bar--done"
      case "planned":
        return "gantt__bar--planned"
      case "in_progress":
        return "gantt__bar--in-progress"
      default:
        return "gantt__bar--in-progress"
    }
  }

  barGridPosition(activity, units) {
    if (!units || units.length === 0) {
      return { gridColumn: "1 / 1" }
    }

    if (!activity.start || !activity.end) {
      return { gridColumn: "1 / 1" }
    }

    const activityStart = activity.start.clone().startOf("day")
    const activityEnd = activity.end.clone().startOf("day")

    // Find which column (unit) contains the start date
    let startColumn = null
    let endColumn = null

    for (let i = 0; i < units.length; i++) {
      const unit = units[i]
      const unitStart = unit.start.clone().startOf("day")
      const unitEnd = unit.end.clone().startOf("day")

      // Check if activity start falls in this unit
      if (startColumn === null) {
        if ((activityStart.isSame(unitStart, "day") || activityStart.isAfter(unitStart, "day")) &&
            (activityStart.isSame(unitEnd, "day") || activityStart.isBefore(unitEnd, "day"))) {
          startColumn = i + 1 // Grid columns are 1-indexed
        }
      }

      // Check if activity end falls in this unit
      if ((activityEnd.isSame(unitStart, "day") || activityEnd.isAfter(unitStart, "day")) &&
          (activityEnd.isSame(unitEnd, "day") || activityEnd.isBefore(unitEnd, "day"))) {
        endColumn = i + 2 // End is exclusive in grid-column, so +2 to span to end of this column
        break
      }
    }

    // If start is before timeline, start at column 1
    if (startColumn === null) {
      startColumn = 1
    }

    // If end is after timeline or not found, end at last column
    if (endColumn === null) {
      endColumn = units.length + 1
    }

    return {
      gridColumn: `${startColumn} / ${endColumn}`
    }
  }

  groupByMonth(units) {
    const groups = []
    units.forEach((unit) => {
      const label = unit.month_label || unit.start.format("MMM-YY")
      const last = groups[groups.length - 1]
      if (last && last.label === label) {
        last.span += 1
      } else {
        groups.push({ label, span: 1 })
      }
    })
    return groups
  }

  isOnOrBefore(dateA, dateB, unit) {
    return dateA.isBefore(dateB, unit) || dateA.isSame(dateB, unit)
  }

  gridTemplateColumnsForUnits(units, columnWidth) {
    if (!units || units.length === 0) {
      return `${columnWidth}px`
    }
    const totalSpan = this.totalSpan(units)
    if (totalSpan <= 0) {
      return `${columnWidth}px`
    }
    // Use fractional units (fr) based on span for proportional sizing
    // This ensures grid columns are sized proportionally to their day span
    return units
      .map((unit) => {
        const span = Math.max(unit?.span || 1, 1)
        return `${span}fr`
      })
      .join(" ")
  }

  totalSpan(units) {
    return units.reduce((total, unit) => {
      if (!unit) return total
      const span = unit.span ?? (unit.end && unit.start ? unit.end.diff(unit.start, "day") + 1 : 0)
      return total + Math.max(span || 0, 0)
    }, 0)
  }

  unitPositionForDate(date, units, includeEndOfDay) {
    if (!date || units.length === 0) return 0

    const target = date.clone().startOf("day")
    const firstUnitStart = units[0].start.clone().startOf("day")
    const lastUnitEnd = units[units.length - 1].end.clone().startOf("day")
    const totalSpan = this.totalSpan(units)

    // If date is before timeline, position at start
    if (target.isBefore(firstUnitStart, "day")) {
      return 0
    }
    // If date is after timeline, position at end
    if (target.isAfter(lastUnitEnd, "day")) {
      return totalSpan
    }

    // Find which unit contains this date and calculate position
    let accumulated = 0
    for (let i = 0; i < units.length; i++) {
      const unit = units[i]
      const unitStart = unit.start.clone().startOf("day")
      const unitEnd = unit.end.clone().startOf("day")
      const spanDays = Math.max(unit.span ?? unitEnd.diff(unitStart, "day") + 1, 1)

      // Check if target date falls within this unit
      const isInUnit = (target.isSame(unitStart, "day") || target.isAfter(unitStart, "day")) &&
                       (target.isSame(unitEnd, "day") || target.isBefore(unitEnd, "day"))

      if (isInUnit) {
        // Calculate how many days from unit start to target
        let offsetDays = target.diff(unitStart, "day")

        // If we want to include the full day (for end dates), add 1
        if (includeEndOfDay) {
          offsetDays += 1
        }

        // Ensure offset doesn't exceed unit span
        offsetDays = Math.min(Math.max(offsetDays, 0), spanDays)

        // Return accumulated position plus offset within current unit
        return accumulated + offsetDays
      }

      // This unit doesn't contain the target, accumulate its span and continue
      accumulated += spanDays
    }

    // Shouldn't reach here if date is within timeline, but return totalSpan as fallback
    return totalSpan
  }

  // Tooltip methods
  showTooltip(event, activity) {
    this.removeTooltip()

    const tooltip = document.createElement("div")
    tooltip.className = "gantt__tooltip"
    tooltip.innerHTML = `
      <div class="gantt__tooltip-title">${activity.title}</div>
      <div class="gantt__tooltip-row">
        <strong>Start</strong>
        <span>${activity.start_label}</span>
      </div>
      <div class="gantt__tooltip-row">
        <strong>Finish</strong>
        <span>${activity.due_label}</span>
      </div>
      ${activity.duration_days ? `
        <div class="gantt__tooltip-row">
          <strong>Duration</strong>
          <span>${activity.duration_days} days</span>
        </div>
      ` : ''}
      ${activity.assignee ? `
        <div class="gantt__tooltip-row">
          <strong>Assignee</strong>
          <span>${activity.assignee}</span>
        </div>
      ` : ''}
      ${activity.discipline ? `
        <div class="gantt__tooltip-row">
          <strong>Discipline</strong>
          <span>${activity.discipline}</span>
        </div>
      ` : ''}
      ${activity.zone ? `
        <div class="gantt__tooltip-row">
          <strong>Zone</strong>
          <span>${activity.zone}</span>
        </div>
      ` : ''}
    `

    document.body.appendChild(tooltip)
    this.currentTooltip = tooltip

    // Position tooltip
    const rect = event.target.getBoundingClientRect()
    const tooltipRect = tooltip.getBoundingClientRect()

    let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2)
    let top = rect.top - tooltipRect.height - 8

    // Keep tooltip on screen
    if (left < 10) left = 10
    if (left + tooltipRect.width > window.innerWidth - 10) {
      left = window.innerWidth - tooltipRect.width - 10
    }
    if (top < 10) {
      top = rect.bottom + 8
    }

    tooltip.style.left = left + "px"
    tooltip.style.top = top + "px"
  }

  removeTooltip() {
    if (this.currentTooltip) {
      this.currentTooltip.remove()
      this.currentTooltip = null
    }
  }

  // Drag and drop methods
  startDrag(event, activity, barElement, start, end) {
    // Prevent drag if it's a quick click
    event.preventDefault()

    this.draggingActivity = activity
    this.draggingBar = barElement
    this.dragStartX = event.clientX
    this.dragTimeline = { start, end }

    const barRect = barElement.getBoundingClientRect()
    const parentRect = barElement.parentElement.getBoundingClientRect()
    this.dragStartOffset = ((barRect.left - parentRect.left) / parentRect.width) * 100

    document.addEventListener("mousemove", this.handleDrag)
    document.addEventListener("mouseup", this.handleDragEnd)

    barElement.classList.add("gantt__bar--dragging")
    this.removeTooltip()
  }

  handleDrag = (event) => {
    if (!this.draggingActivity || !this.draggingBar) return

    const parentRect = this.draggingBar.parentElement.getBoundingClientRect()
    const deltaX = event.clientX - this.dragStartX
    const deltaPercent = (deltaX / parentRect.width) * 100

    let newLeft = this.dragStartOffset + deltaPercent
    newLeft = Math.max(0, Math.min(newLeft, 100 - parseFloat(this.draggingBar.style.width)))

    this.draggingBar.style.left = newLeft + "%"
  }

  handleDragEnd = (event) => {
    if (!this.draggingActivity || !this.draggingBar) return

    document.removeEventListener("mousemove", this.handleDrag)
    document.removeEventListener("mouseup", this.handleDragEnd)

    this.draggingBar.classList.remove("gantt__bar--dragging")

    // Calculate new dates
    const parentRect = this.draggingBar.parentElement.getBoundingClientRect()
    const barRect = this.draggingBar.getBoundingClientRect()
    const newLeftPercent = ((barRect.left - parentRect.left) / parentRect.width) * 100

    const totalDays = this.dragTimeline.end.diff(this.dragTimeline.start, "day")
    const offsetDays = Math.round((newLeftPercent / 100) * totalDays)
    const newStartDate = this.dragTimeline.start.add(offsetDays, "day")

    const duration = this.draggingActivity.duration_days || 1
    const newEndDate = newStartDate.add(duration - 1, "day")

    // Update activity via API
    this.updateActivityDates(this.draggingActivity.id, newStartDate, newEndDate)

    this.draggingActivity = null
    this.draggingBar = null
  }

  async updateActivityDates(activityId, startDate, endDate) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    if (!csrfToken) {
      console.error("CSRF token not found")
      return
    }

    try {
      const response = await fetch(`/activities/${activityId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify({
          activity: {
            start_on: startDate.format("YYYY-MM-DD"),
            due_on: endDate.format("YYYY-MM-DD"),
          }
        })
      })

      if (response.ok) {
        // Show success message
        this.showFlashMessage("Activity rescheduled successfully", "notice")

        // Update the activity in memory
        const activities = [...this.activitiesValue]
        const activityIndex = activities.findIndex(a => a.id === activityId)
        if (activityIndex !== -1) {
          activities[activityIndex].start_on = startDate.format("YYYY-MM-DD")
          activities[activityIndex].due_on = endDate.format("YYYY-MM-DD")
          activities[activityIndex].start_label = startDate.format("MMMM D, YYYY")
          activities[activityIndex].due_label = endDate.format("MMMM D, YYYY")
          this.activitiesValue = activities
        }
      } else {
        this.showFlashMessage("Failed to reschedule activity", "alert")
        // Revert the visual change
        this.render()
      }
    } catch (error) {
      console.error("Error updating activity:", error)
      this.showFlashMessage("Failed to reschedule activity", "alert")
      this.render()
    }
  }

  showFlashMessage(message, type) {
    // Check if flash_toast is available
    if (typeof window.showFlashToast === "function") {
      window.showFlashToast(message, type)
    } else {
      // Fallback to alert
      alert(message)
    }
  }
}
