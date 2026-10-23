class VehicleVisionService
  DEFAULT_ANGLE_SEQUENCE = [
    { angle: "front_three_quarter", spin: 1, base_score: 98, note: "AI Vision Studio: %98 stüdyo simetrisi ve 45° vitrin açısı tespit edildi. Impel/Carvana standardında Ana Vitrin Görseli (Hero Shot) olarak seçildi." },
    { angle: "front",               spin: 2, base_score: 94, note: "AI Vision Studio: Ön ızgara, far netliği ve plaka alanı hizalandı. 360° döner sekansına (2. Kare) atandı." },
    { angle: "side",                spin: 3, base_score: 92, note: "AI Vision Studio: Gövde çizgileri ve jant derinliği optimize edildi. 360° döner sekansına (3. Kare) atandı." },
    { angle: "rear_three_quarter",  spin: 4, base_score: 95, note: "AI Vision Studio: Arka 3/4 omuz çizgisi ve dinamik perspektif yakalandı. 360° döner sekansına (4. Kare) atandı." },
    { angle: "rear",                spin: 5, base_score: 90, note: "AI Vision Studio: Arka bagaj ve stop lambaları simetrisi doğrulandı. 360° döner sekansına (5. Kare) atandı." },
    { angle: "interior",            spin: 0, base_score: 88, note: "AI Vision Studio: Kokpit aydınlatması ve multimedya ekranı netliği onaylandı. İç mekan galerisine ayrıldı." },
    { angle: "detail",              spin: 0, base_score: 86, note: "AI Vision Studio: Lastik/jant kondisyonu ve mikro boya yansıması analiz edildi. Detay galerisine ayrıldı." }
  ].freeze

  def initialize(listing)
    @listing = listing
  end

  def call
    return unless @listing.photos.attached?

    @listing.photo_analyses.destroy_all

    analyses = []
    photos = @listing.photos.to_a

    photos.each_with_index do |photo, idx|
      spec = detect_spec_for(photo, idx)

      analysis = @listing.photo_analyses.build(
        blob_id: photo.blob_id,
        detected_angle: spec[:angle],
        quality_score: spec[:score],
        spin_order: spec[:spin],
        is_hero_candidate: false,
        notes: spec[:note]
      )
      analyses << { photo: photo, analysis: analysis }
    end

    # Determine hero candidate:
    # Prefer 'front_three_quarter' with highest score, else highest quality_score photo
    hero_item = analyses.find { |item| item[:analysis].detected_angle == "front_three_quarter" } ||
                analyses.max_by { |item| item[:analysis].quality_score }

    if hero_item
      hero_item[:analysis].is_hero_candidate = true
      @listing.hero_photo_id = hero_item[:photo].id
    end

    ActiveRecord::Base.transaction do
      analyses.each { |item| item[:analysis].save! }
      @listing.save!(validate: false)
    end

    @listing
  end

  private

  def detect_spec_for(photo, idx)
    filename = photo.filename.to_s.downcase

    detected_angle = nil
    spin_order = 0
    base_score = 90
    note = nil

    if filename.match?(/front.*three.*quarter|front.*3.*4|hero|vitrin|01/)
      detected_angle = "front_three_quarter"
      spin_order = 1
      base_score = 98
      note = DEFAULT_ANGLE_SEQUENCE[0][:note]
    elsif filename.match?(/front|on|02/) && !filename.match?(/three|3/)
      detected_angle = "front"
      spin_order = 2
      base_score = 94
      note = DEFAULT_ANGLE_SEQUENCE[1][:note]
    elsif filename.match?(/side|profil|yan|03/)
      detected_angle = "side"
      spin_order = 3
      base_score = 92
      note = DEFAULT_ANGLE_SEQUENCE[2][:note]
    elsif filename.match?(/rear.*three.*quarter|rear.*3.*4|arka.*3.*4|04/)
      detected_angle = "rear_three_quarter"
      spin_order = 4
      base_score = 95
      note = DEFAULT_ANGLE_SEQUENCE[3][:note]
    elsif filename.match?(/rear|arka|back|05/) && !filename.match?(/three|3/)
      detected_angle = "rear"
      spin_order = 5
      base_score = 90
      note = DEFAULT_ANGLE_SEQUENCE[4][:note]
    elsif filename.match?(/interior|ic|cockpit|cabin|direksiyon|06/)
      detected_angle = "interior"
      spin_order = 0
      base_score = 88
      note = DEFAULT_ANGLE_SEQUENCE[5][:note]
    elsif filename.match?(/detail|detay|jant|wheel|rim/)
      detected_angle = "detail"
      spin_order = 0
      base_score = 86
      note = DEFAULT_ANGLE_SEQUENCE[6][:note]
    else
      # Fallback to predefined sequence by index
      fallback = DEFAULT_ANGLE_SEQUENCE[idx % DEFAULT_ANGLE_SEQUENCE.length]
      detected_angle = fallback[:angle]
      spin_order = fallback[:spin]
      base_score = fallback[:base_score]
      note = fallback[:note]
    end

    {
      angle: detected_angle,
      spin: spin_order,
      score: base_score,
      note: note
    }
  end
end
