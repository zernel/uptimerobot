import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.messageTargets.forEach((message) => {
      this.setupAutoDismiss(message)
    })
  }

  messageTargetConnected(element) {
    this.setupAutoDismiss(element)
  }

  setupAutoDismiss(element) {
    setTimeout(() => {
      this.fadeOut(element)
    }, 5000)
  }

  dismiss(event) {
    this.fadeOut(event.currentTarget.closest("[data-flash-target]"))
  }

  fadeOut(element) {
    if (!element) return

    element.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
    element.style.opacity = "0"
    element.style.transform = "translateY(-8px)"

    setTimeout(() => {
      element.remove()
    }, 300)
  }
}
