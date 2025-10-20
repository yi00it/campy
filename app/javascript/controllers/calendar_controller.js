import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entry", "toggle", "upcomingList", "upcomingEmpty"]
  static values = {
    activity: Boolean,
    meeting: Boolean,
    task: Boolean
  }

  connect() {
    if (!this.hasActivityValue) this.activityValue = false
    if (!this.hasMeetingValue) this.meetingValue = true
    if (!this.hasTaskValue) this.taskValue = true
    this.updateToggleStates()
    this.applyFilter()
  }

  toggle(event) {
    event.preventDefault()
    const type = event.currentTarget.dataset.calendarType
    if (!type) return

    switch (type) {
      case "activity":
        this.activityValue = !this.activityValue
        break
      case "meeting":
        this.meetingValue = !this.meetingValue
        break
      case "task":
        this.taskValue = !this.taskValue
        break
      default:
        break
    }

    this.updateToggleStates()
    this.applyFilter()
  }

  applyFilter() {
    const showActivity = this.activityValue
    const showMeeting = this.meetingValue
    const showTask = this.taskValue

    this.entryTargets.forEach((element) => {
      const category = element.dataset.calendarCategory
      let visible = true
      switch (category) {
        case "activity":
          visible = showActivity
          break
        case "meeting":
          visible = showMeeting
          break
        case "task":
        case "custom":
          visible = showTask
          break
        default:
          visible = showMeeting
      }
      element.hidden = !visible
    })

    this.updateUpcomingVisibility()
  }

  updateToggleStates() {
    this.toggleTargets.forEach((button) => {
      const type = button.dataset.calendarType
      const isActive =
        (type === "activity" && this.activityValue) ||
        (type === "meeting" && this.meetingValue) ||
        (type === "task" && this.taskValue)

      button.classList.toggle("calendar__filter-button--active", isActive)
      button.setAttribute("aria-pressed", isActive)
    })
  }

  updateUpcomingVisibility() {
    if (!this.hasUpcomingListTarget) return

    let anyVisible = false

    this.upcomingListTargets.forEach((list) => {
      const entries = this.entryTargets.filter((entry) => list.contains(entry))
      const listVisible = entries.some((entry) => !entry.hidden)
      list.hidden = !listVisible
      if (listVisible) anyVisible = true
    })

    if (this.hasUpcomingEmptyTarget) {
      this.upcomingEmptyTarget.hidden = anyVisible
    }
  }

}
