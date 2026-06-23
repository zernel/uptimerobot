import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "result", "empty"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
  }

  search() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.performSearch()
    }, 300)
  }

  performSearch() {
    const query = this.inputTarget.value.toLowerCase().trim()

    this.resultTargets.forEach((el) => {
      const text = el.textContent.toLowerCase()
      const matches = query === "" || text.includes(query)
      el.classList.toggle("hidden", !matches)
    })

    if (this.hasEmptyTarget) {
      const visibleResults = this.resultTargets.filter(el => !el.classList.contains("hidden"))
      this.emptyTarget.classList.toggle("hidden", visibleResults.length > 0)
    }
  }

  filterByStatus(event) {
    const status = event.currentTarget.dataset.status
    const allStatuses = event.currentTarget.parentElement.querySelectorAll("[data-status]")

    allStatuses.forEach(btn => {
      btn.classList.remove("bg-slate-900", "text-white")
      btn.classList.add("bg-white", "text-slate-700", "border", "border-slate-300")
    })
    event.currentTarget.classList.remove("bg-white", "text-slate-700", "border", "border-slate-300")
    event.currentTarget.classList.add("bg-slate-900", "text-white")

    this.resultTargets.forEach((el) => {
      if (status === "all") {
        el.classList.remove("hidden")
      } else {
        const elStatus = el.dataset.status
        el.classList.toggle("hidden", elStatus !== status)
      }
    })
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }
}
