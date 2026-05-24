import { Controller } from "@hotwired/stimulus"

// Manages DaisyUI tab ↔ Turbo Frame lazy loading.
//
// The shell page renders Docs inline and three empty <turbo-frame> placeholders
// for Activity, Governance, and Source. This controller:
//   1. On tab click, sets `frame.src` to the island URL (fetched once).
//   2. On connect, auto-selects a tab when the URL carries legacy query params
//      (`?event_name=…` → Activity, `?gov_category=…` → Governance).
export default class extends Controller {
  static targets = ["activity", "governance", "source"]
  static values  = {
    activityUrl:   String,
    governanceUrl: String,
    sourceUrl:     String
  }

  connect() {
    this.loaded = new Set()

    const params = new URLSearchParams(window.location.search)
    if (params.has("event_name")) {
      this.show("activity")
      const url = this.appendParams(this.activityUrlValue, params, ["event_name"])
      this.loadFrame("contract_activity", url)
    } else if (params.has("gov_category")) {
      this.show("governance")
      const url = this.appendParams(this.governanceUrlValue, params, ["gov_category"])
      this.loadFrame("contract_governance", url)
    }
  }

  loadTab(event) {
    const target = event.target
    if (target === this.activityTarget)   this.loadFrame("contract_activity",   this.activityUrlValue)
    if (target === this.governanceTarget) this.loadFrame("contract_governance", this.governanceUrlValue)
    if (target === this.sourceTarget)     this.loadFrame("contract_source",     this.sourceUrlValue)
  }

  // ── private ──────────────────────────────────────────────────────────

  loadFrame(frameId, url) {
    if (this.loaded.has(frameId)) return
    const frame = document.getElementById(frameId)
    if (!frame) return
    frame.src = url
    this.loaded.add(frameId)
  }

  show(target) {
    if (target === "activity"   && this.hasActivityTarget)   this.activityTarget.checked = true
    if (target === "governance" && this.hasGovernanceTarget) this.governanceTarget.checked = true
  }

  appendParams(base, params, keys) {
    const url = new URL(base, window.location.origin)
    keys.forEach(key => {
      if (params.has(key)) url.searchParams.set(key, params.get(key))
    })
    return url.pathname + url.search
  }
}
