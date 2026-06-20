import { Controller } from "@hotwired/stimulus"

// Drives the tournament-view stage selector.
//
// Three coordinated motions make the experience flow:
//   1. stagesWrapper translates horizontally between top-level panels
//      (GS panel ↔ knockout bracket panel).
//   2. bracketTrack inside the bracket panel translates so the active
//      knockout stage's column lines up with the viewport's left edge.
//   3. indicator dot slides under the pill row, centering on the active
//      pill — a spatial cue that the pill row is navigable.
//
// Cards inside the bracket track carry a data-stage attribute; the active
// stage's cards are emphasized (scale-up + full opacity) while the others
// dim, so adjacent stages stay legible without competing for focus.
export default class extends Controller {
  static targets = ["pill", "stagesWrapper", "bracketTrack", "indicator", "indicatorTrack"]
  static values  = { offsets: Object, stageIndices: Object }

  connect() {
    const initial =
      this.pillTargets.find((p) => p.dataset.active === "true")?.dataset.stage ||
      this.pillTargets[0]?.dataset.stage

    if (initial) this.show(initial)

    this.resizeHandler = () => this.updateIndicator()
    window.addEventListener("resize", this.resizeHandler)

    // Run once layout settles (fonts loaded, columns reflowed, etc.).
    requestAnimationFrame(() => this.updateIndicator())
  }

  disconnect() {
    if (this.resizeHandler) window.removeEventListener("resize", this.resizeHandler)
  }

  select(event) {
    const stage = event.currentTarget.dataset.stage
    if (stage) this.show(stage)
  }

  show(stage) {
    this.pillTargets.forEach((pill) => {
      const active = pill.dataset.stage === stage
      pill.dataset.active = active ? "true" : "false"
      pill.classList.toggle("is-active", active)
    })

    if (this.hasStagesWrapperTarget && this.hasStageIndicesValue) {
      const index = this.stageIndicesValue[stage]
      if (typeof index === "number") {
        this.stagesWrapperTarget.style.transform = `translateX(-${index * 100}%)`
      }
    }

    const bracketStages = ["round_of_32", "round_of_16", "quarter_final", "semi_final", "final"]
    const isBracketStage = bracketStages.includes(stage)

    if (isBracketStage && this.hasBracketTrackTarget && this.hasOffsetsValue) {
      const offset = this.offsetsValue[stage]
      if (typeof offset === "number") {
        this.bracketTrackTarget.style.transform = `translateX(${offset}px)`
      }
    }

    if (this.hasBracketTrackTarget) {
      const cards = this.bracketTrackTarget.querySelectorAll("[data-stage]")
      cards.forEach((card) => {
        if (isBracketStage) {
          const isActive = card.dataset.stage === stage
          card.classList.toggle("opacity-40", !isActive)
          card.classList.toggle("scale-105", isActive)
        } else {
          card.classList.remove("opacity-40", "scale-105")
        }
      })
    }

    requestAnimationFrame(() => this.updateIndicator())
  }

  updateIndicator() {
    if (!this.hasIndicatorTarget || !this.hasIndicatorTrackTarget) return
    const activePill = this.pillTargets.find((p) => p.dataset.active === "true")
    if (!activePill) return

    const trackRect = this.indicatorTrackTarget.getBoundingClientRect()
    const pillRect  = activePill.getBoundingClientRect()
    const centerX   = pillRect.left + pillRect.width / 2 - trackRect.left
    this.indicatorTarget.style.left = `${centerX}px`
  }
}
