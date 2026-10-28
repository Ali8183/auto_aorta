import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "slider", "currentFrame", "angleLabel", "spinContainer", "autoPlayBtn"]
  static values = {
    images: Array,
    angles: Array,
    currentIndex: { type: Number, default: 0 }
  }

  connect() {
    this.isDragging = false
    this.startX = 0
    this.startIndex = 0
    this.dragThreshold = 25 // pixels per frame change
    this.autoSpinInterval = null

    this.preloadImages()
    this.updateDisplay()

    // Bind event handlers for smooth window pointerup
    this.handlePointerMove = this.handlePointerMove.bind(this)
    this.handlePointerUp = this.handlePointerUp.bind(this)
  }

  disconnect() {
    this.stopAutoSpin()
    window.removeEventListener("pointermove", this.handlePointerMove)
    window.removeEventListener("pointerup", this.handlePointerUp)
  }

  preloadImages() {
    if (!this.hasImagesValue || this.imagesValue.length === 0) return
    this.imagesValue.forEach((src) => {
      const img = new Image()
      img.src = src
    })
  }

  onPointerDown(event) {
    if (!this.hasImagesValue || this.imagesValue.length <= 1) return

    this.stopAutoSpin()
    this.isDragging = true
    this.startX = event.clientX
    this.startIndex = this.currentIndexValue

    if (this.hasSpinContainerTarget) {
      this.spinContainerTarget.classList.add("cursor-grabbing")
      this.spinContainerTarget.classList.remove("cursor-grab")
    }

    window.addEventListener("pointermove", this.handlePointerMove)
    window.addEventListener("pointerup", this.handlePointerUp)
    event.preventDefault()
  }

  handlePointerMove(event) {
    if (!this.isDragging) return

    const deltaX = event.clientX - this.startX
    const framesShift = Math.floor(deltaX / this.dragThreshold)
    const total = this.imagesValue.length

    // Dragging right rotates car to right, dragging left rotates left
    let newIndex = (this.startIndex - framesShift) % total
    if (newIndex < 0) newIndex += total

    if (newIndex !== this.currentIndexValue) {
      this.currentIndexValue = newIndex
      this.updateDisplay()
    }
  }

  handlePointerUp() {
    if (!this.isDragging) return

    this.isDragging = false
    if (this.hasSpinContainerTarget) {
      this.spinContainerTarget.classList.remove("cursor-grabbing")
      this.spinContainerTarget.classList.add("cursor-grab")
    }

    window.removeEventListener("pointermove", this.handlePointerMove)
    window.removeEventListener("pointerup", this.handlePointerUp)
  }

  onSliderChange(event) {
    this.stopAutoSpin()
    this.currentIndexValue = parseInt(event.target.value, 10)
    this.updateDisplay()
  }

  previousFrame() {
    this.stopAutoSpin()
    const total = this.imagesValue.length
    if (total === 0) return
    this.currentIndexValue = (this.currentIndexValue - 1 + total) % total
    this.updateDisplay()
  }

  nextFrame() {
    this.stopAutoSpin()
    const total = this.imagesValue.length
    if (total === 0) return
    this.currentIndexValue = (this.currentIndexValue + 1) % total
    this.updateDisplay()
  }

  toggleAutoSpin() {
    if (this.autoSpinInterval) {
      this.stopAutoSpin()
    } else {
      this.startAutoSpin()
    }
  }

  startAutoSpin() {
    this.stopAutoSpin()
    if (this.hasAutoPlayBtnTarget) {
      this.autoPlayBtnTarget.innerHTML = `
        <span class="material-symbols-outlined text-sm">pause</span>
        <span>Durdur</span>
      `
    }
    this.autoSpinInterval = setInterval(() => {
      const total = this.imagesValue.length
      if (total <= 1) return
      this.currentIndexValue = (this.currentIndexValue + 1) % total
      this.updateDisplay()
    }, 220)
  }

  stopAutoSpin() {
    if (this.autoSpinInterval) {
      clearInterval(this.autoSpinInterval)
      this.autoSpinInterval = null
    }
    if (this.hasAutoPlayBtnTarget) {
      this.autoPlayBtnTarget.innerHTML = `
        <span class="material-symbols-outlined text-sm">play_arrow</span>
        <span>360° Otomatik Döndür</span>
      `
    }
  }

  selectFrame(event) {
    this.stopAutoSpin()
    const indexAttr = event.currentTarget.dataset.frameIndex
    if (indexAttr !== undefined) {
      const idx = parseInt(indexAttr, 10)
      if (!isNaN(idx) && idx >= 0 && idx < this.imagesValue.length) {
        this.currentIndexValue = idx
        this.updateDisplay()
        return
      }
    }
    const urlAttr = event.currentTarget.dataset.photoUrl
    const angleAttr = event.currentTarget.dataset.photoAngle
    if (urlAttr && this.hasImageTarget) {
      this.imageTarget.src = urlAttr
      if (angleAttr && this.hasAngleLabelTarget) {
        this.angleLabelTarget.textContent = angleAttr
      }
    }
  }

  toggleFullscreen() {
    const container = document.getElementById("turntable-container") || this.element
    if (!document.fullscreenElement) {
      if (container.requestFullscreen) {
        container.requestFullscreen().catch(() => {})
      }
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().catch(() => {})
      }
    }
  }

  resetSpin() {
    this.stopAutoSpin()
    this.currentIndexValue = 0
    this.updateDisplay()
  }

  updateDisplay() {
    const total = this.imagesValue.length
    if (total === 0) return

    const index = this.currentIndexValue

    if (this.hasImageTarget) {
      this.imageTarget.src = this.imagesValue[index]
    }

    if (this.hasSliderTarget) {
      this.sliderTarget.value = index
    }

    if (this.hasCurrentFrameTarget) {
      this.currentFrameTarget.textContent = `${index + 1} / ${total}`
    }

    if (this.hasAngleLabelTarget && this.hasAnglesValue && this.anglesValue[index]) {
      this.angleLabelTarget.textContent = this.anglesValue[index]
    }
  }
}
