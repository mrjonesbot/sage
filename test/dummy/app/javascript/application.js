// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/stimulus"
import "@hotwired/stimulus-loading"
import "controllers/application"

// Import and register all controllers
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import { application } from "controllers/application"
eagerLoadControllersFrom("controllers", application)

// Import and register Sage controllers
import { registerControllers } from "sage"
registerControllers(application)
