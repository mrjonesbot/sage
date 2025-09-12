import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  connect() {
  }

  copy(event) {
    event.preventDefault()
    
    navigator.clipboard.writeText(this.textValue).then(() => {
      const originalText = event.target.textContent
      event.target.textContent = "Copied!"
      event.target.classList.add("btn-success")
      
      setTimeout(() => {
        event.target.textContent = originalText
        event.target.classList.remove("btn-success")
      }, 2000)
    }).catch(err => {
      console.error('Failed to copy text: ', err)
    })
  }
}