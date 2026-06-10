import { Controller } from "@hotwired/stimulus"

// Toggles a group-stage card between collapsed and expanded.
// Drives the chevron rotation and the match list slide via data-expanded.
export default class extends Controller {
  toggle() {
    const expanded = this.element.dataset.expanded === "true"
    this.element.dataset.expanded = expanded ? "false" : "true"
  }
}
