import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    const list = this.element.querySelector(".conversation-messages")
    if (list) {
      requestAnimationFrame(() => {
        list.scrollTop = list.scrollHeight
      })
    }
  }
}
