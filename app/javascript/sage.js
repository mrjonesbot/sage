// Import Turbo
import "@hotwired/turbo-rails"

// Import controllers
import SearchController from "sage/controllers/search_controller"
import ClipboardController from "sage/controllers/clipboard_controller"
import SelectController from "sage/controllers/select_controller"
import DashboardController from "sage/controllers/dashboard_controller"
import ReverseInfiniteScrollController from "sage/controllers/reverse_infinite_scroll_controller"

// Export all Sage controllers for manual registration
export { SearchController, ClipboardController, SelectController, DashboardController, ReverseInfiniteScrollController }

// Register all Sage controllers with the provided Stimulus application
export function registerControllers(application) {
  application.register("sage--search", SearchController)
  application.register("sage--clipboard", ClipboardController)
  application.register("sage--select", SelectController)
  application.register("sage--dashboard", DashboardController)
  application.register("sage--reverse-infinite-scroll", ReverseInfiniteScrollController)
}

