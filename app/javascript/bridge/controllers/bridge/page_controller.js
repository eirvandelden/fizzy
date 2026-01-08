import { BridgeComponent } from "@hotwired/hotwire-native-bridge"
import { BridgeElement } from "@hotwired/hotwire-native-bridge"
import { viewport } from "bridge/helpers/viewport"
import { nextFrame } from "helpers/timing_helpers"

export default class extends BridgeComponent {
  static component = "page"
  static targets = [ "header" ]
  static values = { title: String }

  async connect() {
    super.connect()
    this.notifyBridgeOfPageChange()
    await nextFrame()
    this.startObserver()
    window.addEventListener("resize", this.windowResized)
  }

  disconnect() {
    super.disconnect()
    this.stopObserver()
    window.removeEventListener("resize", this.windowResized)
  }

  receive(message) {
    switch (message.event) {
    case "change":
      this.updateHeaderVisibility(message.data)
      break
    case "set-text-size":
      this.setTextSize(message.data)
      break
    }
  }

  setTextSize(data) {
    document.documentElement.dataset.textSize = data.textSize
  }

  updateHeaderVisibility(data) {
    if (!this.hasHeaderTarget) return

    const headerElement = new BridgeElement(this.headerTarget)

    if (data.displayOnPlatform) {
      headerElement?.showOnPlatform()
    } else {
      headerElement?.hideOnPlatform()
    }
  }

  // Bridge

  notifyBridgeOfPageChange() {
    let headerElement = null
    const data = {
      title: this.title,
      url: window.location.href
    }

    if (this.hasHeaderTarget) {
      // Assume header visible by default until we get IntersectionObserver update
      headerElement = new BridgeElement(this.headerTarget)
      data.elementVisible = true
      data.displayOnPlatform = headerElement.isDisplayedOnPlatform()
    }

    this.send("change", data, message => this.receive(message))
  }

  notifyBridgeOfVisibilityChange(visible) {
    this.send("visibility", { title: this.title, elementVisible: visible })
  }

  // Intersection Observer

  startObserver() {
    if (!this.hasHeaderTarget) return

    this.observer = new IntersectionObserver(([ entry ]) =>
      this.notifyBridgeOfVisibilityChange(entry.isIntersecting),
      { rootMargin: `-${this.topOffset}px 0px 0px 0px` }
    )

    this.observer.observe(this.headerTarget)
    this.previousTopOffset = this.topOffset
  }

  stopObserver() {
    this.observer?.disconnect()
  }

  updateObserverIfNeeded() {
    if (this.topOffset === this.previousTopOffset) return

    this.stopObserver()
    this.startObserver()
  }

  windowResized = () => {
    this.updateObserverIfNeeded()
  }

  get title() {
    return this.titleValue ? this.titleValue : document.title
  }

  get topOffset() {
    return viewport.top
  }
}
