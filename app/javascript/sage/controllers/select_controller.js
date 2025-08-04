import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="select"
export default class extends Controller {
  static targets = ["input", "dropdown", "option", "hidden"];
  static values = { 
    options: Array,
    placeholder: String,
    selected: String,
    maxOptions: { type: Number, default: 100 }
  };

  connect() {
    this.selectedValue = this.selectedValue || "";
    
    // Parse options if they're a string
    let options = this.optionsValue;
    if (typeof options === 'string') {
      try {
        options = JSON.parse(options);
      } catch (e) {
        console.error("Failed to parse options:", e);
        options = [];
      }
    }
    
    this.filteredOptions = Array.isArray(options) ? options.slice(0, this.maxOptionsValue) : [];
    
    // If there's a pre-selected value from the data attribute, set it
    if (this.hasSelectedValue && this.selectedValue) {
      const selectedOption = this.filteredOptions.find(opt => opt.value == this.selectedValue);
      if (selectedOption) {
        this.inputTarget.value = selectedOption.text;
        if (this.hasHiddenTarget) {
          this.hiddenTarget.value = selectedOption.value;
        }
      }
    }
    
    this.render();
    this.setupEventListeners();
  }

  setupEventListeners() {
    // Close dropdown when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this));
    
    // Handle keyboard navigation
    this.inputTarget.addEventListener('keydown', this.handleKeydown.bind(this));
  }

  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this));
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown();
    }
  }

  handleKeydown(event) {
    const dropdown = this.dropdownTarget;
    const options = this.optionTargets;
    const activeOption = dropdown.querySelector('.active');
    
    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.navigateOptions(options, activeOption, 1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.navigateOptions(options, activeOption, -1);
        break;
      case 'Enter':
        event.preventDefault();
        if (activeOption) {
          this.selectOption(activeOption.dataset.value, activeOption.textContent);
        }
        break;
      case 'Escape':
        this.closeDropdown();
        break;
    }
  }

  navigateOptions(options, activeOption, direction) {
    let currentIndex = activeOption ? Array.from(options).indexOf(activeOption) : -1;
    let nextIndex = currentIndex + direction;
    
    if (nextIndex < 0) nextIndex = options.length - 1;
    if (nextIndex >= options.length) nextIndex = 0;
    
    // Remove active class from all options
    options.forEach(option => option.classList.remove('active'));
    
    // Add active class to next option
    if (options[nextIndex]) {
      options[nextIndex].classList.add('active');
      options[nextIndex].scrollIntoView({ block: 'nearest' });
    }
  }

  search(event) {
    const query = event.target.value.toLowerCase().trim();
    
    // Parse options properly
    let options = this.optionsValue;
    if (typeof options === 'string') {
      try {
        options = JSON.parse(options);
      } catch (e) {
        options = [];
      }
    }
    options = Array.isArray(options) ? options : [];
    
    if (query === '' || query === ' ') {
      this.filteredOptions = options.slice(0, this.maxOptionsValue);
    } else {
      this.filteredOptions = options
        .filter(option => option.text.toLowerCase().includes(query))
        .slice(0, this.maxOptionsValue);
    }
    
    this.renderOptions();
    this.openDropdown();
  }

  selectOption(value, text) {
    // Update the input to show selected text
    this.inputTarget.value = text;
    this.selectedValue = value;
    
    // Update hidden field if present
    if (this.hasHiddenTarget) {
      this.hiddenTarget.value = value;
    }
    
    // Dispatch custom event for external handling
    const selectEvent = new CustomEvent('select:change', {
      detail: { value: value, text: text },
      bubbles: true
    });
    this.element.dispatchEvent(selectEvent);
    
    this.closeDropdown();
  }

  openDropdown() {
    this.dropdownTarget.classList.remove('hidden');
    this.dropdownTarget.classList.add('visible');
  }

  closeDropdown() {
    this.dropdownTarget.classList.remove('visible');
    this.dropdownTarget.classList.add('hidden');
  }

  focus() {
    // Reset search to show all options when focusing
    const currentValue = this.inputTarget.value.trim();
    if (currentValue === '' || currentValue === ' ') {
      // Parse options properly
      let options = this.optionsValue;
      if (typeof options === 'string') {
        try {
          options = JSON.parse(options);
        } catch (e) {
          options = [];
        }
      }
      this.filteredOptions = Array.isArray(options) ? options.slice(0, this.maxOptionsValue) : [];
      this.renderOptions();
    }
    this.openDropdown();
  }

  blur() {
    // Delay hiding to allow option clicks
    setTimeout(() => {
      this.closeDropdown();
    }, 150);
  }

  render() {
    // Don't set placeholder for Beer CSS floating labels
    this.renderOptions();
  }

  renderOptions() {
    this.dropdownTarget.innerHTML = '';
    
    if (this.filteredOptions.length === 0) {
      const noResults = document.createElement('div');
      noResults.className = 'select-option no-results';
      noResults.textContent = 'No results found';
      this.dropdownTarget.appendChild(noResults);
      return;
    }
    
    this.filteredOptions.forEach(option => {
      const optionElement = document.createElement('div');
      optionElement.className = 'select-option';
      optionElement.dataset.selectTarget = 'option';
      optionElement.dataset.value = option.value;
      optionElement.textContent = option.text;
      optionElement.addEventListener('click', () => {
        this.selectOption(option.value, option.text);
      });
      this.dropdownTarget.appendChild(optionElement);
    });
  }
}