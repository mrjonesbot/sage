import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "variable"]
  
  connect() {
    // Override the global submitIfCompleted function from Blazer
    window.submitIfCompleted = this.submitIfCompleted.bind(this)
    
    // Set up event listeners for variable changes
    this.setupVariableListeners()
  }
  
  setupVariableListeners() {
    // Listen for changes on all variable inputs
    this.variableTargets.forEach(input => {
      input.addEventListener("change", (event) => {
        this.handleVariableChange(event)
      })
      
      // Also listen for daterangepicker events if present
      if (input.dataset.daterangepicker) {
        const picker = $(input).data('daterangepicker')
        if (picker) {
          $(input).on('apply.daterangepicker', (ev, picker) => {
            this.handleDateRangeChange(input, picker)
          })
        }
      }
    })
  }
  
  handleVariableChange(event) {
    const input = event.target
    
    // Check if all required variables are filled and submit if so
    setTimeout(() => {
      this.submitIfCompleted(this.formTarget)
    }, 100) // Small delay to ensure all values are updated
  }
  
  handleDateRangeChange(input, picker) {
    
    // Force update any related hidden fields
    this.updateRelatedDateFields(input, picker)
    
    // Submit the form after date range is updated
    setTimeout(() => {
      this.submitIfCompleted(this.formTarget)
    }, 200) // Longer delay for date picker updates
  }
  
  updateRelatedDateFields(input, picker) {
    // If this is a start_time/end_time combo, make sure both are updated
    if (input.name === "start_time" || input.name === "end_time") {
      const startTimeInput = this.formTarget.querySelector('input[name="start_time"]')
      const endTimeInput = this.formTarget.querySelector('input[name="end_time"]')
      
      if (startTimeInput && endTimeInput && picker) {
        // Update both fields based on the picker values
        if (picker.startDate) {
          startTimeInput.value = picker.startDate.utc().format()
        }
        if (picker.endDate) {
          endTimeInput.value = picker.endDate.endOf("day").utc().format()
        }
      }
    }
  }
  
  submitIfCompleted(form) {
    if (!form) return
    
    let completed = true
    const requiredInputs = form.querySelectorAll('input[name], select[name]')
    
    // Check each required input
    requiredInputs.forEach(input => {
      const value = input.value
      
      // More robust empty check
      if (this.isEmpty(value)) {
        completed = false
      } else {
      }
    })
    
    
    if (completed) {
      form.submit()
    }
  }
  
  isEmpty(value) {
    // More comprehensive empty check
    return value === null || 
           value === undefined || 
           value === "" || 
           (typeof value === "string" && value.trim() === "")
  }
  
  // Manual trigger for testing
  triggerSubmit() {
    this.submitIfCompleted(this.formTarget)
  }
  
  // Debug method to check current variable states
  debugVariables() {
    const inputs = this.formTarget.querySelectorAll('input[name], select[name]')
  }
}