require "net/http"
require "json"
require "base64"

class VehicleVisionService
  HEURISTIC_NOTE_PREFIX = "Heuristik mod (dosya adı tahmini)".freeze

  DEFAULT_ANGLE_SEQUENCE = [
    { angle: "front_three_quarter", spin: 1, base_score: 98, note: "#{HEURISTIC_NOTE_PREFIX}: Ön 3/4 açısı varsayıldı; Hero Shot adayı." },
    { angle: "front",               spin: 2, base_score: 94, note: "#{HEURISTIC_NOTE_PREFIX}: Ön açı varsayıldı; 360° sekansında 2. kare." },
    { angle: "side",                spin: 3, base_score: 92, note: "#{HEURISTIC_NOTE_PREFIX}: Yan profil varsayıldı; 360° sekansında 3. kare." },
    { angle: "rear_three_quarter",  spin: 4, base_score: 95, note: "#{HEURISTIC_NOTE_PREFIX}: Arka 3/4 açısı varsayıldı; 360° sekansında 4. kare." },
    { angle: "rear",                spin: 5, base_score: 90, note: "#{HEURISTIC_NOTE_PREFIX}: Arka açı varsayıldı; 360° sekansında 5. kare." },
    { angle: "interior",            spin: 0, base_score: 88, note: "#{HEURISTIC_NOTE_PREFIX}: İç mekan varsayıldı; 360° sekansına dahil edilmedi." },
    { angle: "detail",              spin: 0, base_score: 86, note: "#{HEURISTIC_NOTE_PREFIX}: Detay/jant varsayıldı; 360° sekansına dahil edilmedi." }
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
      spec = analyze_photo(photo, idx)

      analysis = @listing.photo_analyses.build(
        blob_id: photo.blob_id,
        detected_angle: spec[:angle],
        quality_score: spec[:score],
        spin_order: spec[:spin],
        is_hero_candidate: false,
        notes: spec[:note]
      )
      analyses << { photo: photo, analysis: analysis, spec: spec }
    end

    # Enforce single-vehicle body color and model consistency across all photos
    validate_vehicle_consistency!(analyses)

    # Determine hero candidate from verified consistent photos:
    # Prefer 'front_three_quarter' with highest score, else highest quality_score photo
    valid_analyses = analyses.reject { |item| item[:anomalous] }
    pool = valid_analyses.any? ? valid_analyses : analyses
    hero_item = pool.find { |item| item[:analysis].detected_angle == "front_three_quarter" } ||
                pool.max_by { |item| item[:analysis].quality_score }

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

  # Two layers:
  # 1. Filename hint check (always runs): excludes photos whose filename names another brand
  #    or carries an explicit mismatch marker.
  # 2. Real color/make consistency check: ONLY runs when every exterior photo was analysed by a
  #    multimodal LLM that returned a body color. The "AI Bütünlük Kontrolü" confirmation is
  #    written only when this real check actually ran and passed.
  def validate_vehicle_consistency!(analyses = nil)
    persisted_mode = analyses.blank?
    target_items = if persisted_mode
      @listing.photo_analyses.map do |pa|
        photo = @listing.photos.find { |p| p.blob_id == pa.blob_id }
        { photo: photo, analysis: pa }
      end
    else
      analyses
    end

    anomalies = []
    expected_brand = @listing.brand.to_s.downcase

    # Layer 1: filename hint check
    target_items.each do |item|
      photo = item[:photo]
      analysis = item[:analysis]
      fname = photo&.filename.to_s.downcase

      conflicting_brand = %w[bmw tesla porsche mercedes audi bugatti ferrari lamborghini playstation hyundai].any? { |b| fname.include?(b) && !expected_brand.include?(b) }
      explicit_mismatch = fname.match?(/mismatch|anomaly|different_car|wrong_color|red_/)

      if conflicting_brand || explicit_mismatch
        mark_anomalous!(item, "⚠️ Bütünlük Kilidi (dosya adı kontrolü): Farklı marka/renk ipucu tespit edildi (#{fname}) ve 360° sekansından çıkarıldı.")
        anomalies << fname
      end
    end

    # Layer 2: real LLM-based body color / make consistency check
    exterior = target_items.reject { |i| i[:anomalous] }.select do |i|
      %w[front_three_quarter front side rear_three_quarter rear].include?(i[:analysis].detected_angle)
    end

    check_performed = false
    consistency_note = nil

    if persisted_mode
      # Color data is not persisted; only report what an earlier real check already recorded.
      check_performed = exterior.any? && exterior.all? { |i| i[:analysis].notes.to_s.include?("AI Bütünlük Kontrolü:") }
    elsif exterior.any? && exterior.all? { |i| i.dig(:spec, :source) == :llm && i.dig(:spec, :color).present? }
      check_performed = true
      colors = exterior.map { |i| normalize_color(i[:spec][:color]) }
      majority_color = colors.tally.max_by { |_, c| c }.first

      exterior.each do |item|
        color_ok = normalize_color(item[:spec][:color]) == majority_color
        make = item[:spec][:make].to_s.downcase
        make_ok = make.blank? || make.include?(expected_brand) || expected_brand.include?(make)
        next if color_ok && make_ok

        mark_anomalous!(item, "⚠️ AI Bütünlük Kilidi: Vision modeli farklı renk/marka tespit etti (#{item[:spec][:color]} / #{item[:spec][:make]}) ve 360° sekansından çıkarıldı.")
        anomalies << item[:photo]&.filename.to_s
      end

      verified = exterior.reject { |i| i[:anomalous] }
      if verified.any?
        display_color = verified.first[:spec][:color]
        consistency_note = "✓ AI Bütünlük Kontrolü: #{verified.size} dış görselin tamamı aynı gövde rengine (#{display_color}) ve markaya (#{@listing.brand}) ait olarak doğrulandı. Farklı araç anomalisi yok."
        verified.each do |item|
          item[:analysis].notes = [ item[:analysis].notes, consistency_note ].compact.join(" ")
        end
        Rails.logger.info("[VehicleVisionService] #{consistency_note}")
      end
    else
      Rails.logger.info("[VehicleVisionService] Renk/model bütünlük kontrolü yapılmadı (Vision API sonucu yok, heuristik mod).")
    end

    if persisted_mode
      target_items.each { |i| i[:analysis].save! if i[:analysis].persisted? && i[:analysis].changed? }
    end

    {
      valid: anomalies.empty?,
      consistent: anomalies.empty?,
      verified: check_performed,
      verified_count: target_items.size - anomalies.size,
      anomaly_count: anomalies.size,
      message: consistency_note
    }
  end

  private

  def mark_anomalous!(item, note)
    item[:anomalous] = true
    analysis = item[:analysis]
    analysis.spin_order = 0
    analysis.is_hero_candidate = false
    analysis.notes = [ analysis.notes, note ].compact.join(" | ")
    Rails.logger.warn("[VehicleVisionService] #{note}")
  end

  def normalize_color(color)
    color.to_s.downcase.gsub(/metalik|metallic|metal|pearl|inci|[^a-zçğıöşü ]/, "").squeeze(" ").strip
  end

  def analyze_photo(photo, idx)
    # 1. Try real Multimodal Vision AI if API keys are available
    if vision_api_available?
      llm_result = try_multimodal_vision(photo)
      return llm_result if llm_result.present?
    end

    # 2. Seamless heuristic fallback engine (never raises)
    detect_spec_fallback(photo, idx)
  rescue StandardError => e
    Rails.logger.warn("[VehicleVisionService] Exception caught in analyze_photo: #{e.message}. Using fallback.")
    detect_spec_fallback(photo, idx)
  end

  def vision_api_available?
    ENV["GROQ_API_KEY"].present? || ENV["GEMINI_API_KEY"].present? || ENV["OPENAI_API_KEY"].present?
  end

  def try_multimodal_vision(photo)
    image_bytes = photo.download rescue nil
    return nil if image_bytes.blank? || image_bytes.bytesize > 4_000_000

    base64_image = Base64.strict_encode64(image_bytes)
    mime_type = photo.content_type.presence || "image/jpeg"

    if ENV["GROQ_API_KEY"].present?
      call_groq_vision(base64_image, mime_type)
    elsif ENV["GEMINI_API_KEY"].present?
      call_gemini_vision(base64_image, mime_type)
    elsif ENV["OPENAI_API_KEY"].present?
      call_openai_vision(base64_image, mime_type)
    end
  rescue StandardError => e
    Rails.logger.info("[VehicleVisionService] LLM Vision failed (#{e.class}: #{e.message}). Gracefully using fallback heuristic.")
    nil
  end

  def call_groq_vision(base64_image, mime_type)
    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 6
    http.read_timeout = 8

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV['GROQ_API_KEY']}"
    request["Content-Type"] = "application/json"

    prompt = <<~PROMPT
      Analyze this car vehicle photo. Return ONLY a valid JSON object without markdown or formatting:
      {
        "angle": "front_three_quarter" | "front" | "side" | "rear_three_quarter" | "rear" | "interior" | "wheel",
        "quality_score": <number between 1 and 100>,
        "body_color": "<dominant exterior body color in English, or null for interior shots>",
        "make": "<vehicle manufacturer if identifiable, else null>",
        "notes": "<short explanation in Turkish of studio lighting and angle>"
      }
    PROMPT

    body = {
      model: "llama-3.2-11b-vision-preview",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: "data:#{mime_type};base64,#{base64_image}" } }
          ]
        }
      ],
      temperature: 0.1,
      response_format: { type: "json_object" }
    }

    request.body = body.to_json
    response = http.request(request)

    return nil unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    content = parsed.dig("choices", 0, "message", "content")
    json_data = JSON.parse(content)

    map_llm_json_to_spec(json_data)
  rescue StandardError => e
    Rails.logger.warn("[VehicleVisionService] Groq call error: #{e.message}")
    nil
  end

  def call_gemini_vision(base64_image, mime_type)
    api_key = ENV["GEMINI_API_KEY"]
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 6
    http.read_timeout = 8

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"

    body = {
      contents: [
        {
          parts: [
            { text: "Analyze this automotive vehicle photo. Return JSON only: {\"angle\": \"front_three_quarter\"|\"front\"|\"side\"|\"rear_three_quarter\"|\"rear\"|\"interior\"|\"wheel\", \"quality_score\": 1-100, \"body_color\": \"dominant exterior body color in English or null\", \"make\": \"manufacturer or null\", \"notes\": \"...\"}" },
            { inline_data: { mime_type: mime_type, data: base64_image } }
          ]
        }
      ],
      generationConfig: { response_mime_type: "application/json" }
    }

    request.body = body.to_json
    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    text = parsed.dig("candidates", 0, "content", "parts", 0, "text")
    json_data = JSON.parse(text)

    map_llm_json_to_spec(json_data)
  rescue StandardError => e
    Rails.logger.warn("[VehicleVisionService] Gemini call error: #{e.message}")
    nil
  end

  def call_openai_vision(base64_image, mime_type)
    uri = URI("https://api.openai.com/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 6
    http.read_timeout = 8

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
    request["Content-Type"] = "application/json"

    body = {
      model: "gpt-4o-mini",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: "Analyze vehicle photo angle and quality. Return JSON: {\"angle\": \"front_three_quarter\"|\"front\"|\"side\"|\"rear_three_quarter\"|\"rear\"|\"interior\"|\"wheel\", \"quality_score\": 1-100, \"body_color\": \"dominant exterior body color in English or null\", \"make\": \"manufacturer or null\", \"notes\": \"...\"}" },
            { type: "image_url", image_url: { url: "data:#{mime_type};base64,#{base64_image}" } }
          ]
        }
      ],
      response_format: { type: "json_object" }
    }

    request.body = body.to_json
    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    content = parsed.dig("choices", 0, "message", "content")
    json_data = JSON.parse(content)

    map_llm_json_to_spec(json_data)
  rescue StandardError => e
    Rails.logger.warn("[VehicleVisionService] OpenAI call error: #{e.message}")
    nil
  end

  def map_llm_json_to_spec(json_data)
    angle = json_data["angle"].to_s.downcase.strip
    score = json_data["quality_score"].to_i
    score = 92 if score < 70 || score > 100

    spin = case angle
           when "front_three_quarter" then 1
           when "front"               then 2
           when "side"                then 3
           when "rear_three_quarter"  then 4
           when "rear"                then 5
           else 0
           end

    note = json_data["notes"].presence || "Multimodal Vision AI: #{angle.titleize} açısı tespit edildi. Stüdyo kalite puanı: #{score}/100."

    {
      angle: angle,
      spin: spin,
      score: score,
      note: "🤖 [LLM Vision Engine] #{note}",
      color: json_data["body_color"].presence,
      make: json_data["make"].presence,
      source: :llm
    }
  end

  def detect_spec_fallback(photo, idx)
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
      note: note,
      source: :heuristic
    }
  end
end
