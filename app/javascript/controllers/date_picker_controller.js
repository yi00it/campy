import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    default: { type: Boolean, default: false }
  }

  connect() {
    if (this.defaultValue && !this.element.value) {
      this.element.value = this.tomorrowString()
    }
  }

  open() {
    if (this.element.showPicker) {
      this.element.showPicker()
    }
  }

  tomorrowString() {
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const month = String(tomorrow.getMonth() + 1).padStart(2, "0")
    const day = String(tomorrow.getDate()).padStart(2, "0")
    return `${tomorrow.getFullYear()}-${month}-${day}`
  }
}
