import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle() {
    try {
      const content = this.contentTarget
      const icon = this.iconTarget
      
      const isHidden = window.getComputedStyle(content).display === "none"
      
      if (isHidden) {
        content.style.display = "block"
        icon.textContent = "visibility_off"
      } else {
        content.style.display = "none"
        icon.textContent = "visibility"
      }
    } catch (error) {
      console.error("Error in toggle:", error)
    }
  }
}
