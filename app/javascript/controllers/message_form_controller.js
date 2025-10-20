import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.form = this.element
    this.focusInput()
    this.element.addEventListener("turbo:submit-start", this.disableForm)
    this.element.addEventListener("turbo:submit-end", this.afterSubmit)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.disableForm)
    this.element.removeEventListener("turbo:submit-end", this.afterSubmit)
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.form.requestSubmit()
    }
  }

  disableForm = () => {
    this.setSubmitting(true)
  }

  afterSubmit = (event) => {
    this.setSubmitting(false)
    if (event.detail?.success) {
      this.clearInput()
      this.focusInput()
    }
  }

  clearInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.style.height = ""
    }
  }

  focusInput() {
    if (this.hasInputTarget) {
      requestAnimationFrame(() => this.inputTarget.focus())
    }
  }

  setSubmitting(state) {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = state
    }
    if (this.hasInputTarget) {
      this.inputTarget.readOnly = state
    }
  }
}
