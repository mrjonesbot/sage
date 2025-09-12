import { Controller } from "@hotwired/stimulus";
import debounce from "debounce";

// Connects to data-controller="search"
export default class extends Controller {
  initialize() {
    this.submit = debounce(this.submit.bind(this), 300);
    this.searchInput = null;
  }

  connect() {
    // Find the search input
    this.searchInput = this.element.querySelector('input[type="search"]');

    if (this.searchInput) {
      // Focus the input
      if (this.searchInput.value.length > 0) {
        this.searchInput.focus();
      }

      // If we have a stored cursor position, restore it
      if (this.cursorPosition !== undefined) {
        this.searchInput.setSelectionRange(
          this.cursorPosition,
          this.cursorPosition
        );
        // Clear the stored position after using it
        this.cursorPosition = undefined;
      } else {
        // If no stored position, place cursor at the end
        const length = this.searchInput.value.length;
        this.searchInput.setSelectionRange(length, length);
      }
    }
  }

  submit(event) {
    // Store the cursor position before submitting
    if (this.searchInput) {
      this.cursorPosition = this.searchInput.selectionStart;
    }

    this.element.requestSubmit();
  }
}

