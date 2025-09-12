import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle() {
    try {
      const content = this.contentTarget
      const icon = this.iconTarget
      
      if (content.style.display === "none") {
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
