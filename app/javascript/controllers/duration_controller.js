import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["start", "duration", "due"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    if (!this.hasStartTarget || !this.hasDurationTarget || !this.hasDueTarget) return

    const startValue = this.startTarget.value
    const durationValue = parseInt(this.durationTarget.value, 10)

    if (!startValue || Number.isNaN(durationValue) || durationValue <= 0) {
      return
    }

    const startDate = new Date(startValue)
    if (Number.isNaN(startDate.getTime())) return

    const dueDate = new Date(startDate)
    dueDate.setDate(dueDate.getDate() + durationValue)

    const formatted = dueDate.toISOString().slice(0, 10)
    this.dueTarget.value = formatted
  }
}
