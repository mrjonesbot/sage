pin "sage/application", to: "sage/application.js", preload: true
pin "sage", to: "sage.js"
pin "sage/controllers/search_controller", to: "sage/controllers/search_controller.js"
pin "sage/controllers/clipboard_controller", to: "sage/controllers/clipboard_controller.js"
pin "sage/controllers/select_controller", to: "sage/controllers/select_controller.js"
pin "sage/controllers/dashboard_controller", to: "sage/controllers/dashboard_controller.js"
pin "sage/controllers/reverse_infinite_scroll_controller", to: "sage/controllers/reverse_infinite_scroll_controller.js"
pin "sage/controllers/variables_controller", to: "sage/controllers/variables_controller.js"
pin "sage/controllers/query_toggle_controller", to: "sage/controllers/query_toggle_controller.js"

# External dependencies
pin "debounce", to: "https://ga.jspm.io/npm:debounce@2.0.0/index.js"

# Don't pin common libraries - let the host app handle them
# pin "@hotwired/stimulus", to: "stimulus.min.js"
# pin "@hotwired/turbo-rails", to: "turbo.min.js"
