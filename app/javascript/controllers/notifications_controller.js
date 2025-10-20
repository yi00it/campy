import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge", "dropdown"]
  static values = {
    pollInterval: { type: Number, default: 30000 } // Poll every 30 seconds
  }

  connect() {
    console.log("Notifications controller connected!")
    console.log("Has dropdown target:", this.hasDropdownTarget)
    console.log("Has badge target:", this.hasBadgeTarget)
    this.updateCount()
    this.startPolling()
    this.currentFilter = "all"
  }

  disconnect() {
    this.stopPolling()
    this.removeOutsideClickListener()
  }

  startPolling() {
    this.pollTimer = setInterval(() => {
      this.updateCount()
    }, this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
    }
  }

  async updateCount() {
    try {
      const response = await fetch("/notifications/unread_count", {
        headers: {
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateBadge(data.count)
      }
    } catch (error) {
      console.error("Failed to update notification count:", error)
    }
  }

  updateBadge(count) {
    if (this.hasBadgeTarget) {
      if (count > 0) {
        this.badgeTarget.textContent = count > 99 ? "99+" : count
        this.badgeTarget.style.display = "flex"
      } else {
        this.badgeTarget.style.display = "none"
      }
    }
  }

  async toggle(event) {
    console.log("Toggle clicked!")
    event.preventDefault()
    event.stopPropagation()

    console.log("Has dropdown target:", this.hasDropdownTarget)
    if (this.hasDropdownTarget) {
      const isVisible = this.dropdownTarget.classList.contains("notification-dropdown--visible")
      console.log("Is visible:", isVisible)

      if (isVisible) {
        this.hideDropdown()
      } else {
        await this.showDropdown()
      }
    } else {
      console.error("Dropdown target not found!")
    }
  }

  async showDropdown() {
    console.log("showDropdown called")
    // Load notifications
    await this.loadDropdownContent()

    console.log("Adding visible class")
    this.dropdownTarget.classList.add("notification-dropdown--visible")
    document.addEventListener("click", this.handleOutsideClick)
    console.log("Dropdown should be visible now")
  }

  hideDropdown() {
    this.dropdownTarget.classList.remove("notification-dropdown--visible")
    this.removeOutsideClickListener()
  }

  removeOutsideClickListener() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  async loadDropdownContent() {
    console.log("Loading dropdown content...")
    try {
      const response = await fetch("/notifications/dropdown", {
        headers: {
          "Accept": "text/html"
        }
      })

      console.log("Response status:", response.status)
      if (response.ok) {
        const html = await response.text()
        console.log("HTML loaded, length:", html.length)
        this.dropdownTarget.innerHTML = html
        console.log("HTML inserted into dropdown")
      } else {
        console.error("Response not OK:", response.status, response.statusText)
      }
    } catch (error) {
      console.error("Failed to load notifications:", error)
    }
  }

  filterTab(event) {
    const button = event.currentTarget
    const filterType = button.dataset.type

    // Update active tab
    this.element.querySelectorAll(".notification-tab").forEach(tab => {
      tab.classList.remove("notification-tab--active")
    })
    button.classList.add("notification-tab--active")

    // Filter notifications
    const notifications = this.dropdownTarget.querySelectorAll(".notification-item")

    notifications.forEach(notification => {
      const notificationType = notification.dataset.type

      if (filterType === "all" || notificationType === filterType) {
        notification.style.display = "flex"
      } else {
        notification.style.display = "none"
      }
    })

    // Update group visibility
    this.updateGroupVisibility()
  }

  updateGroupVisibility() {
    const groups = this.dropdownTarget.querySelectorAll(".notification-group")

    groups.forEach(group => {
      const visibleItems = group.querySelectorAll('.notification-item[style*="display: flex"], .notification-item:not([style*="display: none"])')

      if (visibleItems.length === 0) {
        group.style.display = "none"
      } else {
        group.style.display = "block"
      }
    })
  }

  async markAsRead(event) {
    event.preventDefault()

    const link = event.currentTarget
    const notificationId = link.dataset.notificationId
    const url = link.href

    try {
      await fetch(`/notifications/${notificationId}/mark_as_read`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      this.updateCount()

      // Navigate to the notification URL
      window.location.href = url
    } catch (error) {
      console.error("Failed to mark notification as read:", error)
      // Navigate anyway
      window.location.href = url
    }
  }
}
