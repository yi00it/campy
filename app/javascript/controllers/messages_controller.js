import { Controller } from "@hotwired/stimulus"

const STREAM_EVENT = "turbo:before-stream-render"

export default class extends Controller {
  static targets = ["list"]
  static values = { conversationId: String }

  connect() {
    this.scrollToBottom()
    document.addEventListener(STREAM_EVENT, this.handleStream)
    this.setupObserver()
  }

  disconnect() {
    document.removeEventListener(STREAM_EVENT, this.handleStream)
    this.teardownObserver()
  }

  handleStream = (event) => {
    const targetId = event?.target?.getAttribute("target")
    if (!targetId || !this.hasConversationIdValue) return
    if (targetId !== `${this.conversationIdValue}_messages`) return

    requestAnimationFrame(() => this.scrollToBottom())
  }

  setupObserver() {
    if (!this.hasListTarget) return
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.listTarget, { childList: true })
  }

  teardownObserver() {
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
  }

  scrollToBottom() {
    const list = this.hasListTarget ? this.listTarget : this.element.querySelector(".conversation-messages")
    if (!list) return
    list.scrollTop = list.scrollHeight
  }
}
