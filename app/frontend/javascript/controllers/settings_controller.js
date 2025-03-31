import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "link"]

  connect() {
    // Show personal access tokens section by default
    this.showSection("personal-access-tokens")
  }

  switch(event) {
    event.preventDefault()
    const targetId = event.currentTarget.getAttribute("href").substring(1)
    this.showSection(targetId)
  }

  showSection(sectionId) {
    // Update active state of links
    this.linkTargets.forEach(link => {
      link.classList.remove("bg-gray-100")
      if (link.getAttribute("href") === `#${sectionId}`) {
        link.classList.add("bg-gray-100")
      }
    })

    // Show/hide content sections
    this.sectionTargets.forEach(section => {
      section.classList.add("hidden")
      if (section.id === sectionId) {
        section.classList.remove("hidden")
      }
    })
  }
} 