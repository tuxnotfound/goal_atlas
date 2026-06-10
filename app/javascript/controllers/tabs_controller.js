import { Controller } from "@hotwired/stimulus"

// Generic tab toggle. Tabs and panels share data-panel; clicking a tab marks
// it active and shows the matching panel while hiding the rest.
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const initial =
      this.tabTargets.find((t) => t.dataset.active === "true")?.dataset.panel ||
      this.tabTargets[0]?.dataset.panel
    if (initial) this.show(initial)
  }

  switch(event) {
    const panel = event.currentTarget.dataset.panel
    if (panel) this.show(panel)
  }

  show(panel) {
    this.tabTargets.forEach((tab) => {
      tab.dataset.active = tab.dataset.panel === panel ? "true" : "false"
    })
    this.panelTargets.forEach((p) => {
      p.classList.toggle("hidden", p.dataset.panel !== panel)
    })
  }
}
