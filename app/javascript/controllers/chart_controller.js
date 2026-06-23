import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    data: Array,
    label: { type: String, default: "Response Time (ms)" }
  }

  connect() {
    this.loadChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  async loadChart() {
    if (!window.Chart) {
      await this.loadScript("https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js")
    }
    this.renderChart()
  }

  loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = src
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  renderChart() {
    if (!this.hasCanvasTarget || !this.hasLabelsValue || !this.hasDataValue) return

    const ctx = this.canvasTarget.getContext("2d")

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [{
          label: this.labelValue,
          data: this.dataValue,
          borderColor: "#10b981",
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          borderWidth: 2,
          fill: true,
          tension: 0.3,
          pointRadius: 3,
          pointHoverRadius: 6,
          pointBackgroundColor: "#10b981",
          pointBorderColor: "#ffffff",
          pointBorderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: "index"
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: "#1e293b",
            titleColor: "#f8fafc",
            bodyColor: "#cbd5e1",
            borderColor: "#334155",
            borderWidth: 1,
            padding: 12,
            displayColors: false,
            callbacks: {
              label: (context) => `${context.parsed.y} ms`
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: "#94a3b8",
              font: { size: 11 },
              maxRotation: 0
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: "rgba(148, 163, 184, 0.1)"
            },
            ticks: {
              color: "#94a3b8",
              font: { size: 11 },
              callback: (value) => `${value} ms`
            }
          }
        }
      }
    })
  }
}
