import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = {
    storageKey: { type: String, default: "sage_query_sql_visibility" }
  }

  connect() {
    // Load saved visibility state from localStorage
    this.loadVisibilityState()
  }

  toggle() {
    try {
      const content = this.contentTarget
      const icon = this.iconTarget

      const isHidden = window.getComputedStyle(content).display === "none"

      if (isHidden) {
        this.showContent()
      } else {
        this.hideContent()
      }
    } catch (error) {
      console.error("Error in toggle:", error)
    }
  }

  showContent() {
    this.contentTarget.style.display = "block"
    this.iconTarget.textContent = "visibility_off"
    this.saveVisibilityState(true)
  }

  hideContent() {
    this.contentTarget.style.display = "none"
    this.iconTarget.textContent = "visibility"
    this.saveVisibilityState(false)
  }

  saveVisibilityState(isVisible) {
    try {
      localStorage.setItem(this.storageKeyValue, JSON.stringify(isVisible))
    } catch (error) {
      console.error("Error saving visibility state:", error)
    }
  }

  loadVisibilityState() {
    try {
      const savedState = localStorage.getItem(this.storageKeyValue)
      if (savedState !== null) {
        const isVisible = JSON.parse(savedState)
        if (isVisible) {
          this.showContent()
        } else {
          this.hideContent()
        }
      }
    } catch (error) {
      console.error("Error loading visibility state:", error)
    }
  }
}
