import { Controller } from "@hotwired/stimulus"

// Filters a player's goal lane by tournament year. Pills carry data-year;
// goal entries carry data-year. Clicking a pill toggles visibility on each
// entry. "All" is the special "year" — shows every goal.
export default class extends Controller {
  static targets = ["pill", "entry", "empty"]

  connect() {
    const initial =
      this.pillTargets.find((p) => p.dataset.active === "true")?.dataset.year || "all"
    this.show(initial)
  }

  select(event) {
    const year = event.currentTarget.dataset.year
    if (year) this.show(year)
  }

  show(year) {
    this.pillTargets.forEach((pill) => {
      const active = pill.dataset.year === year
      pill.dataset.active = active ? "true" : "false"
    })

    let visible = 0
    this.entryTargets.forEach((entry) => {
      const match = year === "all" || entry.dataset.year === year
      entry.classList.toggle("hidden", !match)
      if (match) visible += 1
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible > 0)
    }
  }
}
