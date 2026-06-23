import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("click", this.closeOnOutsideClick)
    }
  }

  close(event) {
    event?.stopPropagation()
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  openSidebar() {
    const sidebar = document.getElementById("sidebar")
    const backdrop = document.getElementById("sidebar-backdrop")
    if (sidebar) sidebar.classList.remove("-translate-x-full")
    if (backdrop) backdrop.classList.remove("hidden")
  }

  closeSidebar() {
    const sidebar = document.getElementById("sidebar")
    const backdrop = document.getElementById("sidebar-backdrop")
    if (sidebar) sidebar.classList.add("-translate-x-full")
    if (backdrop) backdrop.classList.add("hidden")
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }
}
