// Sage Stimulus controllers initialization
// This file is loaded via importmap and registers all Sage controllers with the host app's Stimulus instance

import { registerControllers } from "sage"

// Wait for the host app's Stimulus to be available
if (window.Stimulus) {
  registerControllers(window.Stimulus)
} else {
  // If Stimulus isn't ready yet, wait for it
  document.addEventListener('DOMContentLoaded', () => {
    if (window.Stimulus) {
      registerControllers(window.Stimulus)
    }
  })
}
