import { Controller } from "@hotwired/stimulus"

// Simple modal controller to toggle visibility and focus trap
export default class extends Controller {
  static targets = ["container", "dialog", "backdrop"]

  connect() {
    this.active = false
    this.handleContainerClick = this.handleContainerClick.bind(this)
    this.containerEl = this.element.querySelector("[data-modal-target='container']")
    this.dialogEl = this.element.querySelector("[data-modal-target='dialog']")
    this.backdropEl = this.element.querySelector("[data-modal-target='backdrop']")

    if (this.containerEl) {
      if (!this.placeholder) {
        this.placeholder = document.createComment("modal-placeholder")
        this.containerEl.after(this.placeholder)
      }
      this.containerEl.hidden = true
      this.containerEl.ariaHidden = "true"
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    if (this.active) {
      this.hide()
    }
    if (this.containerEl) {
      this.containerEl.removeEventListener("click", this.handleContainerClick)
    }
    this.removePlaceholder()
  }

  open(event) {
    event.preventDefault()
    if (this.active || !this.dialogEl || !this.backdropEl || !this.containerEl) return

    this.show()
    this.previousFocus = document.activeElement
    this.focusFirstInput()

    document.addEventListener("keydown", this.handleEscape)
  }

  close(event) {
    if (event) event.preventDefault()
    if (!this.active) return

    this.hide()
    document.removeEventListener("keydown", this.handleEscape)
    if (this.previousFocus) this.previousFocus.focus()
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close(event)
  }

  handleBackdrop(event) {
    if (!this.active) return
    if (event.target === this.backdropEl) {
      this.close(event)
    }
  }

  handleEscape = (event) => {
    if (event.key === "Escape") this.close(event)
  }

  show() {
    if (!this.containerEl) return

    if (this.containerEl.parentElement !== document.body) {
      document.body.appendChild(this.containerEl)
    }

    this.containerEl.hidden = false
    this.containerEl.ariaHidden = "false"
    if (this.dialogEl) {
      this.dialogEl.hidden = false
      this.dialogEl.ariaHidden = "false"
    }
    if (this.backdropEl) {
      this.backdropEl.hidden = false
      this.backdropEl.ariaHidden = "false"
    }
    this.active = true
    this.containerEl.addEventListener("click", this.handleContainerClick)
    document.body.classList.add("modal-open")
  }

  hide() {
    if (!this.containerEl) return

    if (this.dialogEl) {
      this.dialogEl.hidden = true
      this.dialogEl.ariaHidden = "true"
    }
    if (this.backdropEl) {
      this.backdropEl.hidden = true
      this.backdropEl.ariaHidden = "true"
    }

    this.containerEl.hidden = true
    this.containerEl.ariaHidden = "true"
    this.active = false
    this.containerEl.removeEventListener("click", this.handleContainerClick)
    document.body.classList.remove("modal-open")

    if (this.placeholder?.parentNode && this.containerEl.parentElement === document.body) {
      this.placeholder.parentNode.insertBefore(this.containerEl, this.placeholder)
    }
  }

  handleContainerClick(event) {
    const trigger = event.target.closest("[data-modal-close]")
    if (trigger) {
      this.close(event)
    }
  }

  focusFirstInput() {
    if (!this.dialogEl) return
    const input = this.dialogEl.querySelector("textarea, input, select, button")
    if (input) input.focus()
  }

  removePlaceholder() {
    if (this.placeholder?.parentNode) {
      this.placeholder.parentNode.removeChild(this.placeholder)
      this.placeholder = null
    }
  }
}
