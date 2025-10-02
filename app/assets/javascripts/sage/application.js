// Sage application JavaScript
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Import and register Sage controllers
import { SearchController, ClipboardController, SelectController, DashboardController, ReverseInfiniteScrollController, VariablesController, QueryToggleController } from "sage"

const application = Application.start()
application.debug = true
window.Stimulus = application

// Register controllers
application.register("sage--search", SearchController)
application.register("sage--clipboard", ClipboardController)
application.register("sage--select", SelectController)
application.register("sage--dashboard", DashboardController)
application.register("sage--reverse-infinite-scroll", ReverseInfiniteScrollController)
application.register("sage--variables", VariablesController)
application.register("sage--query-toggle", QueryToggleController)

// Override Blazer's submitIfCompleted function globally
window.submitIfCompleted = function($form) {
  // Try to find our Sage variables controller first
  const controller = document.querySelector('[data-controller*="sage--variables"]')
  if (controller && window.Stimulus) {
    const controllerInstance = window.Stimulus.getControllerForElementAndIdentifier(controller, 'sage--variables')
    if (controllerInstance) {
      controllerInstance.submitIfCompleted($form[0] || $form)
      return
    }
  }
  
  // Fallback to improved version of original logic
  var completed = true
  $form.find("input[name], select").each(function () {
    const value = $(this).val()
    if (!value || value.toString().trim() === "") {
      completed = false
    }
  })
  if (completed) {
    $form.submit()
  }
}
