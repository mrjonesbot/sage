// Sage application JavaScript
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Import and register Sage controllers
import { SearchController, ClipboardController, SelectController, DashboardController, ReverseInfiniteScrollController } from "sage"

const application = Application.start()
application.debug = true
window.Stimulus = application

// Register controllers
application.register("sage--search", SearchController)
application.register("sage--clipboard", ClipboardController)
application.register("sage--select", SelectController)
application.register("sage--dashboard", DashboardController)
application.register("sage--reverse-infinite-scroll", ReverseInfiniteScrollController)
