import { Controller } from "@hotwired/stimulus";

console.log("Reverse infinite scroll controller file loaded!");

export default class extends Controller {
  static targets = ["entries", "pagination"];
  static values = {
    url: String,
    page: Number,
    loading: Boolean,
  };

  initialize() {
    console.log("Reverse infinite scroll controller initialized");
    this.intersectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            console.log("Pagination target is visible - loading older messages");
            this.loadOlder();
          }
        });
      },
      {
        rootMargin: "50px 0px 50px 0px",
        threshold: 0.1,
      }
    );
  }

  connect() {
    console.log("Reverse infinite scroll controller connected");
    console.log("Initial page value:", this.pageValue);
    
    if (this.hasPaginationTarget) {
      console.log("Found pagination target, observing...");
      this.intersectionObserver.observe(this.paginationTarget);
    } else {
      console.log("No pagination target found");
    }
  }

  paginationTargetConnected(target) {
    console.log("Pagination target connected dynamically, observing...");
    // Add a delay to allow scroll-to-bottom to happen first
    setTimeout(() => {
      console.log("Starting to observe pagination target after delay");
      this.intersectionObserver.observe(target);
    }, 1000);
  }

  paginationTargetDisconnected(target) {
    console.log("Pagination target disconnected, stop observing...");
    this.intersectionObserver.unobserve(target);
  }

  disconnect() {
    console.log("Reverse infinite scroll controller disconnected");
    this.intersectionObserver.disconnect();
  }

  buildUrl(nextPage) {
    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("page", nextPage);
    return url.toString();
  }

  async loadOlder() {
    if (this.loadingValue) {
      console.log("Already loading, skipping...");
      return;
    }

    console.log("Loading older messages...");
    console.log("Current pageValue:", this.pageValue);
    this.loadingValue = true;
    const nextPage = this.pageValue + 1;
    console.log("Requesting page:", nextPage);

    // Store current scroll position
    const oldScrollHeight = this.element.scrollHeight;
    const oldScrollTop = this.element.scrollTop;

    try {
      const url = this.buildUrl(nextPage);
      console.log("Fetching URL:", url);
      
      const response = await fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const html = await response.text();
      console.log("Received response for page", nextPage);

      // Parse the turbo-stream content
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const template = doc.querySelector("template");

      if (template) {
        // Remove the current pagination target before appending new content
        if (this.hasPaginationTarget) {
          this.paginationTarget.remove();
        }

        // Manually prepend the template content (for reverse infinite scroll)
        this.entriesTarget.insertAdjacentHTML("afterbegin", template.innerHTML);
        this.pageValue = nextPage;
        console.log(`Updated to page ${nextPage}`);

        // Maintain scroll position (prevent jumping to top)
        setTimeout(() => {
          const newScrollHeight = this.element.scrollHeight;
          const heightDifference = newScrollHeight - oldScrollHeight;
          this.element.scrollTop = oldScrollTop + heightDifference;
          
          console.log("Scroll position updated:", {
            oldScrollHeight,
            newScrollHeight,
            heightDifference,
            newScrollTop: this.element.scrollTop
          });

          // Set up observer for new pagination target if it exists
          if (this.hasPaginationTarget) {
            console.log("Found new pagination target, observing...");
            this.intersectionObserver.observe(this.paginationTarget);
          } else {
            console.log("No more pages to load");
          }
        }, 50);
      }
    } catch (error) {
      console.error("Error loading older messages:", error);
      console.log("Staying on page", this.pageValue, "due to error");
    } finally {
      this.loadingValue = false;
    }
  }
}
