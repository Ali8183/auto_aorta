import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "video",
    "canvas",
    "ringAlert",
    "completionAlert",
    "recordBtn",
    "recordBtnText",
    "recordBtnIcon",
    "downloadBtn",
    "totalCounter",
    "sectorCounter",
    "ringName",
    "ringLevelBadge",
    "ringProgressBar",
    "totalProgressBar",
    "frameGallery",
    "statusBadge"
  ]

  static values = {
    listingId: Number,
    downloadUrl: String
  }

  connect() {
    this.rings = [
      { id: "dusuk", name: "Düşük Seviye", desc: "Tampon / Tekerlek Hizası (~0.5m)", height: "düşük" },
      { id: "orta", name: "Orta Seviye", desc: "Far / Kapı Kolu Hizası (~1.2m)", height: "orta" },
      { id: "yuksek", name: "Yüksek Seviye", desc: "Tavan / Omuz Hizası (~1.8m)", height: "yüksek" }
    ]
    this.sectorsPerRing = 36
    this.totalTargetFrames = 108

    this.currentRingIdx = 0
    this.currentSector = 1
    this.totalCaptured = 0
    this.isRecording = false
    this.timerInterval = null
    this.capturedFrames = []

    this.initCamera()
    this.updateUI()
  }

  disconnect() {
    this.stopRecording()
    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach((track) => track.stop())
    }
  }

  async initCamera() {
    try {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        this.mediaStream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "environment", width: { ideal: 1280 }, height: { ideal: 720 } },
          audio: false
        })
        if (this.hasVideoTarget) {
          this.videoTarget.srcObject = this.mediaStream
          await this.videoTarget.play().catch(() => {})
        }
      }
    } catch (err) {
      console.info("[VehicleCapture] Live camera stream unavailable, using synthetic simulator feed:", err)
      this.startSimulationFeed()
    }
  }

  startSimulationFeed() {
    if (!this.hasCanvasTarget) return
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    let angle = 0

    const drawSim = () => {
      if (!this.mediaStream) {
        ctx.fillStyle = "#0f172a"
        ctx.fillRect(0, 0, canvas.width, canvas.height)

        // Draw simulated car silhouette on dark studio backdrop
        ctx.save()
        ctx.translate(canvas.width / 2, canvas.height / 2)
        ctx.rotate((angle * Math.PI) / 180)

        ctx.strokeStyle = "rgba(59, 130, 246, 0.4)"
        ctx.lineWidth = 2
        ctx.beginPath()
        ctx.arc(0, 0, 110, 0, Math.PI * 2)
        ctx.stroke()

        ctx.fillStyle = "#1e293b"
        ctx.fillRect(-60, -35, 120, 70)
        ctx.fillStyle = "#38bdf8"
        ctx.font = "bold 12px sans-serif"
        ctx.textAlign = "center"
        ctx.fillText("SIMÜLASYON KAMERA", 0, 5)
        ctx.restore()

        angle = (angle + 1.5) % 360
        requestAnimationFrame(drawSim)
      }
    }
    requestAnimationFrame(drawSim)
  }

  toggleRecording() {
    if (this.isRecording) {
      this.stopRecording()
    } else {
      this.startRecording()
    }
  }

  startRecording() {
    if (this.totalCaptured >= this.totalTargetFrames) return
    this.isRecording = true
    this.updateRecordButtonState(true)

    // Capture a frame every 380ms
    this.timerInterval = setInterval(() => {
      this.captureStep()
    }, 380)
  }

  stopRecording() {
    this.isRecording = false
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
    this.updateRecordButtonState(false)
  }

  captureStep() {
    if (this.totalCaptured >= this.totalTargetFrames) {
      this.completeCaptureSession()
      return
    }

    const ring = this.rings[this.currentRingIdx]
    const sector = this.currentSector
    const frameNumber = this.totalCaptured + 1

    // 1. Capture snapshot image data
    const dataUrl = this.grabFrameDataUrl(ring.height, sector, frameNumber)

    // 2. Store frame with metadata
    const frameMeta = {
      index: frameNumber,
      ring: ring.height, // "düşük", "orta", "yüksek"
      ring_index: this.currentRingIdx + 1,
      sector: sector, // 1..36
      timestamp: new Date().toISOString(),
      filename: `frame_${String(frameNumber).padStart(3, "0")}_halka_${this.currentRingIdx + 1}_${ring.id}_sektor_${String(sector).padStart(2, "0")}.jpg`,
      data: dataUrl
    }
    this.capturedFrames.push(frameMeta)
    this.totalCaptured += 1

    this.prependThumbnail(frameMeta)

    // Check if current ring is finished (36 sectors completed)
    if (this.currentSector >= this.sectorsPerRing) {
      this.stopRecording()

      if (this.currentRingIdx < 2) {
        // Show ring transition alert: "Şimdi telefonu bir seviye alçalt/yükselt ve tekrar dön"
        this.showRingTransitionAlert()
      } else {
        // All 3 rings done (108 frames)
        this.completeCaptureSession()
      }
    } else {
      this.currentSector += 1
    }

    this.updateUI()
  }

  showRingTransitionAlert() {
    if (this.hasRingAlertTarget) {
      this.ringAlertTarget.classList.remove("hidden")
      this.ringAlertTarget.classList.add("flex")
    }
  }

  resumeNextRing() {
    if (this.hasRingAlertTarget) {
      this.ringAlertTarget.classList.add("hidden")
      this.ringAlertTarget.classList.remove("flex")
    }
    this.currentRingIdx += 1
    this.currentSector = 1
    this.updateUI()
    this.startRecording()
  }

  completeCaptureSession() {
    this.stopRecording()
    if (this.hasCompletionAlertTarget) {
      this.completionAlertTarget.classList.remove("hidden")
      this.completionAlertTarget.classList.add("flex")
    }
    if (this.hasDownloadBtnTarget) {
      this.downloadBtnTarget.classList.remove("opacity-50", "pointer-events-none")
      this.downloadBtnTarget.classList.add("animate-bounce")
    }
    if (this.hasStatusBadgeTarget) {
      this.statusBadgeTarget.textContent = "✓ 108 Kare Çekim Tamamlandı"
      this.statusBadgeTarget.className = "px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-300 text-xs font-bold"
    }
    this.updateUI()
  }

  grabFrameDataUrl(ringHeight, sector, index) {
    const canvas = document.createElement("canvas")
    canvas.width = 640
    canvas.height = 480
    const ctx = canvas.getContext("2d")

    if (this.hasVideoTarget && this.videoTarget.videoWidth > 0) {
      ctx.drawImage(this.videoTarget, 0, 0, canvas.width, canvas.height)
    } else {
      // Synthetic canvas drawing
      ctx.fillStyle = "#0f172a"
      ctx.fillRect(0, 0, canvas.width, canvas.height)
      ctx.fillStyle = "#38bdf8"
      ctx.font = "bold 24px sans-serif"
      ctx.textAlign = "center"
      ctx.fillText(`AutoAorta AI Capture`, canvas.width / 2, canvas.height / 2 - 20)
      ctx.font = "14px sans-serif"
      ctx.fillStyle = "#94a3b8"
      ctx.fillText(`Halka: ${ringHeight} | Sektör: ${sector}/36 | Kare: ${index}/108`, canvas.width / 2, canvas.height / 2 + 15)
    }

    // Telemetry stamp overlay
    ctx.fillStyle = "rgba(15, 23, 42, 0.75)"
    ctx.fillRect(10, canvas.height - 35, canvas.width - 20, 25)
    ctx.fillStyle = "#38bdf8"
    ctx.font = "11px monospace"
    ctx.textAlign = "left"
    ctx.fillText(`AutoAorta AI • Ring: ${ringHeight} • Sector: ${sector}/36 • Frame: ${index}/108`, 18, canvas.height - 18)

    return canvas.toDataURL("image/jpeg", 0.85)
  }

  prependThumbnail(frameMeta) {
    if (!this.hasFrameGalleryTarget) return
    const el = document.createElement("div")
    el.className = "w-16 h-12 rounded-lg bg-slate-900 border border-slate-700 overflow-hidden flex-shrink-0 relative group"
    el.innerHTML = `
      <img src="${frameMeta.data}" class="w-full h-full object-cover" />
      <span class="absolute bottom-0.5 right-0.5 px-1 py-0.2 rounded bg-slate-950/80 text-[8px] text-white font-mono">
        ${frameMeta.sector}
      </span>
    `
    this.frameGalleryTarget.prepend(el)
  }

  updateUI() {
    const ring = this.rings[this.currentRingIdx] || this.rings[0]

    if (this.hasTotalCounterTarget) {
      this.totalCounterTarget.textContent = `${this.totalCaptured} / ${this.totalTargetFrames}`
    }

    if (this.hasSectorCounterTarget) {
      this.sectorCounterTarget.textContent = `${this.currentSector} / ${this.sectorsPerRing}`
    }

    if (this.hasRingNameTarget) {
      this.ringNameTarget.textContent = `Halka ${this.currentRingIdx + 1}: ${ring.name} (${ring.desc})`
    }

    if (this.hasRingProgressBarTarget) {
      const ringPct = Math.min(100, (this.currentSector / this.sectorsPerRing) * 100)
      this.ringProgressBarTarget.style.width = `${ringPct}%`
    }

    if (this.hasTotalProgressBarTarget) {
      const totalPct = Math.min(100, (this.totalCaptured / this.totalTargetFrames) * 100)
      this.totalProgressBarTarget.style.width = `${totalPct}%`
    }
  }

  updateRecordButtonState(recording) {
    if (!this.hasRecordBtnTarget) return
    if (recording) {
      this.recordBtnTarget.className = "px-6 py-3 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs flex items-center gap-2 shadow-sm transition cursor-pointer"
      if (this.hasRecordBtnTextTarget) this.recordBtnTextTarget.textContent = "Kaydı Duraklat"
      if (this.hasRecordBtnIconTarget) this.recordBtnIconTarget.textContent = "pause"
    } else {
      this.recordBtnTarget.className = "px-6 py-3 rounded-xl bg-[#1D4ED8] hover:bg-blue-800 text-white font-bold text-xs flex items-center gap-2 shadow-sm transition cursor-pointer"
      if (this.hasRecordBtnTextTarget) this.recordBtnTextTarget.textContent = "Çekimi Başlat"
      if (this.hasRecordBtnIconTarget) this.recordBtnIconTarget.textContent = "play_arrow"
    }
  }

  async downloadZip() {
    const url = this.downloadUrlValue || `/listings/${this.listingIdValue || 1}/download_capture_zip`

    // Create a form to download file via POST with frames JSON
    const form = document.createElement("form")
    form.method = "POST"
    form.action = url
    form.style.display = "none"

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "frames"
    input.value = JSON.stringify(this.capturedFrames)
    form.appendChild(input)

    document.body.appendChild(form)
    form.submit()
    setTimeout(() => form.remove(), 1000)
  }

  resetCapture() {
    this.stopRecording()
    this.currentRingIdx = 0
    this.currentSector = 1
    this.totalCaptured = 0
    this.capturedFrames = []
    if (this.hasFrameGalleryTarget) this.frameGalleryTarget.innerHTML = ""
    if (this.hasRingAlertTarget) this.ringAlertTarget.classList.add("hidden")
    if (this.hasCompletionAlertTarget) this.completionAlertTarget.classList.add("hidden")
    this.updateUI()
  }
}

