import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "modal", "modalTitle", "modalPart", "modalMicron", "modalType", "modalDesc", "modalSeverity"]
  static values = {
    images: Array,
    defects: Array,
    autoplay: { type: Boolean, default: false },
    dragSpeed: { type: Number, default: 120 }
  }

  connect() {
    this.viewerInstance = null;
    this.boundBeforeCache = this.beforeCache.bind(this);
    document.addEventListener("turbo:before-cache", this.boundBeforeCache);

    this.loadScriptAndInit();
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache);
    this.destroyViewer();
  }

  beforeCache() {
    this.destroyViewer();
  }

  loadScriptAndInit() {
    const cdnUrl = "https://cdn.cloudimage.io/360-view/4.10.0/360-view.min.js";

    if (window.CI360) {
      this.initCloudimage360();
      return;
    }

    // Check if script is already injected
    let script = document.querySelector(`script[src="${cdnUrl}"]`);
    if (!script) {
      script = document.createElement("script");
      script.src = cdnUrl;
      script.async = true;
      document.head.appendChild(script);
    }

    script.addEventListener("load", () => {
      this.initCloudimage360();
    });

    // Fallback if CDN fails or takes too long: enable basic drag turntable
    this.fallbackTimeout = setTimeout(() => {
      if (!this.viewerInstance && !window.CI360) {
        this.initFallbackTurntable();
      }
    }, 2500);
  }

  initCloudimage360() {
    if (!this.hasContainerTarget || !window.CI360) return;
    clearTimeout(this.fallbackTimeout);

    try {
      const images = this.imagesValue || [];
      if (images.length === 0) return;

      const container = this.containerTarget;
      // Assign a stable ID if not present
      if (!container.id) {
        container.id = `ci360-${Math.random().toString(36).substring(2, 9)}`;
      }

      // Build hotspots from defectsValue
      const hotspots = (this.defectsValue || []).map((defect, idx) => {
        const frameIdx = defect.frame_index || 0;
        const posX = defect.position_x || 50;
        const posY = defect.position_y || 50;

        return {
          id: `defect-hotspot-${defect.id || idx}`,
          orientation: 'x',
          positions: {
            [frameIdx]: { x: posX, y: posY }
          },
          label: defect.part_name || defect.title,
          content: `<div class="p-2 text-xs font-sans">
                      <strong class="text-white">${defect.part_name || defect.title}</strong>
                      <p class="text-slate-300 text-[11px] mt-0.5">${defect.micron_value ? defect.micron_value + ' µm' : ''} ${defect.defect_type || ''}</p>
                    </div>`,
          onClick: () => {
            this.openDefectModal(defect);
          }
        };
      });

      const config = {
        imageListX: images,
        amountX: images.length,
        autoplay: this.autoplayValue,
        speed: 90,
        dragSpeed: this.dragSpeedValue,
        inertia: true,
        theme: 'dark',
        hints: false,
        fullscreen: false,
        bottomCircle: false,
        initialIconShown: false,
        hotspots: hotspots.length > 0 ? hotspots : undefined,
        hotspotTrigger: 'hover',
        hotspotTimelineOnClick: true
      };

      this.ci360Manager = new window.CI360();
      this.ci360Manager.init(container, config);
      this.viewerInstance = this.ci360Manager.getViewById(container.id);
    } catch (err) {
      console.warn("CI360 init error, switching to fallback turntable:", err);
      this.initFallbackTurntable();
    }
  }

  destroyViewer() {
    try {
      if (this.viewerInstance && typeof this.viewerInstance.destroy === "function") {
        this.viewerInstance.destroy();
      } else if (this.ci360Manager && this.hasContainerTarget) {
        const view = this.ci360Manager.getViewById(this.containerTarget.id);
        if (view && typeof view.destroy === "function") {
          view.destroy();
        }
      }
    } catch (e) {
      // Ignored
    }
    this.viewerInstance = null;
    this.ci360Manager = null;
  }

  // Fallback simple touch/drag turntable if CDN is offline
  initFallbackTurntable() {
    if (!this.hasContainerTarget) return;
    const container = this.containerTarget;
    const images = this.imagesValue || [];
    if (images.length === 0) return;

    let currentIndex = 0;
    let isDragging = false;
    let startX = 0;

    container.innerHTML = "";
    container.classList.add("relative", "flex", "items-center", "justify-center", "cursor-grab", "select-none");

    const img = document.createElement("img");
    img.src = images[0];
    img.className = "max-h-full max-w-full object-contain pointer-events-none transition-opacity duration-75";
    container.appendChild(img);

    const onPointerDown = (e) => {
      isDragging = true;
      startX = e.clientX || (e.touches && e.touches[0].clientX) || 0;
      container.classList.add("cursor-grabbing");
    };

    const onPointerMove = (e) => {
      if (!isDragging) return;
      const currentX = e.clientX || (e.touches && e.touches[0].clientX) || 0;
      const diff = currentX - startX;
      if (Math.abs(diff) > 15) {
        if (diff > 0) {
          currentIndex = (currentIndex - 1 + images.length) % images.length;
        } else {
          currentIndex = (currentIndex + 1) % images.length;
        }
        img.src = images[currentIndex];
        startX = currentX;
      }
    };

    const onPointerUp = () => {
      isDragging = false;
      container.classList.remove("cursor-grabbing");
    };

    container.addEventListener("mousedown", onPointerDown);
    window.addEventListener("mousemove", onPointerMove);
    window.addEventListener("mouseup", onPointerUp);

    container.addEventListener("touchstart", onPointerDown, { passive: true });
    window.addEventListener("touchmove", onPointerMove, { passive: true });
    window.addEventListener("touchend", onPointerUp);

    this.fallbackCleanup = () => {
      container.removeEventListener("mousedown", onPointerDown);
      window.removeEventListener("mousemove", onPointerMove);
      window.removeEventListener("mouseup", onPointerUp);
      container.removeEventListener("touchstart", onPointerDown);
      window.removeEventListener("touchmove", onPointerMove);
      window.removeEventListener("touchend", onPointerUp);
    };
  }

  openDefectModal(defect) {
    if (!this.hasModalTarget) return;

    if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = defect.title || defect.part_name;
    if (this.hasModalPartTarget) this.modalPartTarget.textContent = defect.part_name || "Gövde Aksamı";
    if (this.hasModalMicronTarget) this.modalMicronTarget.textContent = defect.micron_value ? `${defect.micron_value} µm` : "Fabrika Değeri";
    if (this.hasModalTypeTarget) this.modalTypeTarget.textContent = defect.defect_type || "Kozmetik";
    if (this.hasModalDescTarget) this.modalDescTarget.textContent = defect.description || "Ekspertiz teknisyeni tarafından incelenmiştir.";
    if (this.hasModalSeverityTarget) {
      this.modalSeverityTarget.textContent = defect.severity === "minor" ? "Hafif Kusur (Vernik / Taş İzi)" : "Onaylı Ekspertiz Kaydı";
    }

    this.modalTarget.classList.remove("hidden");
    this.modalTarget.classList.add("flex");
    document.body.classList.add("overflow-hidden");
  }

  closeModal() {
    if (!this.hasModalTarget) return;
    this.modalTarget.classList.add("hidden");
    this.modalTarget.classList.remove("flex");
    document.body.classList.remove("overflow-hidden");
  }
}
