import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "campy-theme"

// Toggles between light and dark themes by setting data-theme on <body>
export default class extends Controller {
  static targets = ["label"]

  connect() {
    const stored = this.storedTheme
    this.theme = stored ? stored : "light"
    this.applyTheme()
  }

  toggle(event) {
    event.preventDefault()
    this.theme = this.theme === "dark" ? "light" : "dark"
    this.applyTheme()
    window.localStorage.setItem(STORAGE_KEY, this.theme)
  }

  applyTheme() {
    if (this.theme === "dark") {
      document.body.dataset.theme = "dark"
    } else {
      delete document.body.dataset.theme
    }
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.theme === "dark" ? "Light mode" : "Dark mode"
    }
  }

  get storedTheme() {
    return window.localStorage.getItem(STORAGE_KEY)
  }

  get prefersDark() {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
  }
}
