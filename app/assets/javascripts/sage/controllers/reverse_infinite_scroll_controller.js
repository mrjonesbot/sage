import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["entries", "pagination"];
  static values = {
    url: String,
    page: Number,
    loading: Boolean,
  };

  initialize() {
    this.intersectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
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
    if (this.hasPaginationTarget) {
      this.intersectionObserver.observe(this.paginationTarget);
    } else {
    }
  }

  paginationTargetConnected(target) {
    // Add a delay to allow scroll-to-bottom to happen first
    setTimeout(() => {
      this.intersectionObserver.observe(target);
    }, 1000);
  }

  paginationTargetDisconnected(target) {
    this.intersectionObserver.unobserve(target);
  }

  disconnect() {
    this.intersectionObserver.disconnect();
  }

  buildUrl(nextPage) {
    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("page", nextPage);
    return url.toString();
  }

  async loadOlder() {
    if (this.loadingValue) {
      return;
    }

    this.loadingValue = true;
    const nextPage = this.pageValue + 1;

    // Store current scroll position
    const oldScrollHeight = this.element.scrollHeight;
    const oldScrollTop = this.element.scrollTop;

    try {
      const url = this.buildUrl(nextPage);
      
      const response = await fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const html = await response.text();

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

        // Maintain scroll position (prevent jumping to top)
        setTimeout(() => {
          const newScrollHeight = this.element.scrollHeight;
          const heightDifference = newScrollHeight - oldScrollHeight;
          this.element.scrollTop = oldScrollTop + heightDifference;
          
          // Set up observer for new pagination target if it exists
          if (this.hasPaginationTarget) {
            this.intersectionObserver.observe(this.paginationTarget);
          }
        }, 50);
      }
    } catch (error) {
    } finally {
      this.loadingValue = false;
    }
  }
}
