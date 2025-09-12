import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dashboard"
export default class extends Controller {
  static targets = ["queryList", "queryTemplate"];
  static values = { queries: Array };

  connect() {
    // Parse the queries value if it's a string
    const queriesData = typeof this.queriesValue === 'string' ? 
      JSON.parse(this.queriesValue) : this.queriesValue;
    this.selectedQueries = Array.isArray(queriesData) ? [...queriesData] : [];
    this.render();
    this.setupSortable();
  }

  addQuery(event) {
    const { value, text } = event.detail;
    
    // Check for duplicates and remove if found
    const existingIndex = this.selectedQueries.findIndex(q => q.id == value);
    if (existingIndex !== -1) {
      this.selectedQueries.splice(existingIndex, 1);
    }
    
    // Add the new query
    this.selectedQueries.push({ id: value, name: text });
    this.render();
  }

  removeQuery(event) {
    const index = parseInt(event.params.index);
    this.selectedQueries.splice(index, 1);
    this.render();
  }

  render() {
    // Check if the target exists
    if (!this.hasQueryListTarget) {
      console.error("queryList target not found");
      return;
    }
    
    if (this.selectedQueries.length === 0) {
      this.queryListTarget.style.display = 'none';
      return;
    }

    this.queryListTarget.style.display = 'block';
    let queriesContainer = this.queryListTarget.querySelector('#queries');
    
    // If the container doesn't exist, create it
    if (!queriesContainer) {
      queriesContainer = document.createElement('div');
      queriesContainer.id = 'queries';
      queriesContainer.style.display = 'flex';
      queriesContainer.style.flexDirection = 'column';
      queriesContainer.style.gap = '8px';
      this.queryListTarget.appendChild(queriesContainer);
    }
    
    queriesContainer.innerHTML = '';
    
    this.selectedQueries.forEach((query, index) => {
      // Create a plain div without any Beer CSS classes
      const item = document.createElement('div');
      // Remove ALL classes and use inline styles only
      item.style.cssText = `
        display: flex !important;
        align-items: center !important;
        width: 100% !important;
        padding: 12px !important;
        margin-bottom: 8px !important;
        background-color: #f5f5f5 !important;
        border-radius: 8px !important;
        opacity: 1 !important;
        filter: none !important;
      `;
      
      // Use a Material Icons checkbox instead of HTML input
      const checkIcon = document.createElement('i');
      checkIcon.className = 'material-icons';
      checkIcon.textContent = 'check_box';
      checkIcon.style.cssText = 'color: #6750A4 !important; margin-right: 12px !important; font-size: 24px !important;';
      
      const text = document.createElement('strong');  // Use strong tag
      text.textContent = query.name;
      text.style.cssText = 'flex: 1 !important; color: #000000 !important; opacity: 1 !important; filter: none !important;';
      
      const closeBtn = document.createElement('i');
      closeBtn.className = 'material-icons';
      closeBtn.textContent = 'close';
      closeBtn.style.cssText = 'cursor: pointer !important; color: #000000 !important; opacity: 1 !important; font-size: 20px !important;';
      closeBtn.setAttribute('data-action', 'click->sage--dashboard#removeQuery');
      closeBtn.setAttribute('data-sage--dashboard-index-param', index);
      
      const hiddenInput = document.createElement('input');
      hiddenInput.type = 'hidden';
      hiddenInput.name = 'query_ids[]';
      hiddenInput.value = query.id;
      
      item.appendChild(checkIcon);
      item.appendChild(text);
      item.appendChild(closeBtn);
      item.appendChild(hiddenInput);
      
      queriesContainer.appendChild(item);
    });
  }

  setupSortable() {
    if (typeof Sortable !== 'undefined') {
      const queriesContainer = this.queryListTarget.querySelector('#queries');
      if (queriesContainer) {
        Sortable.create(queriesContainer, {
          onEnd: (e) => {
            // Move the item in our array to match the new position
            const movedItem = this.selectedQueries.splice(e.oldIndex, 1)[0];
            this.selectedQueries.splice(e.newIndex, 0, movedItem);
            this.render();
          }
        });
      }
    }
  }
}
