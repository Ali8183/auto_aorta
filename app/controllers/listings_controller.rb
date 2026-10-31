class ListingsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :download_capture_zip ]
  before_action :set_listing, only: %i[show destroy optimize publish simulate_time_lapse capture download_capture_zip]

  def index
    @listings = Listing.with_attached_photos.includes(:photo_analyses).order(created_at: :desc)
  end

  def show
    # Trigger SLA check if it's optimized and time expired
    @listing.auto_publish_if_expired!

    @photo_analyses = @listing.photo_analyses.order(is_hero_candidate: :desc, spin_order: :asc, quality_score: :desc)
    @spin_photos = @listing.spin_photos
    @hero_analysis = @listing.hero_photo_analysis
  end

  def new
    @listing = Listing.new(
      brand: "BMW",
      model_name: "320i M Sport",
      year: 2023,
      fuel_type: "Benzin",
      transmission: "Otomatik",
      mileage: 28500,
      price: 2850000
    )
  end

  def create
    @listing = Listing.new(listing_params)

    if @listing.save
      # Automatically run AI Vision optimization if photos were uploaded
      if @listing.photos.attached?
        @listing.start_ai_optimization!
        redirect_to @listing, notice: "İlan oluşturuldu ve AI Vision Studio tarafından analiz edilerek vitrin görselleri optimize edildi!"
      else
        redirect_to @listing, notice: "İlan taslak olarak kaydedildi. Lütfen fotoğraf yükleyiniz."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def optimize
    @listing.start_ai_optimization!
    redirect_to @listing, notice: "AI Studio Analizi tamamlandı: 360° döner sekans sıralandı ve Ana Vitrin Görseli (Hero Shot) seçildi!"
  end

  def publish
    @listing.publish!
    redirect_to @listing, notice: "İlan başarıyla yayına alındı! Artık vitrinde aktif."
  end

  def simulate_time_lapse
    @listing.start_ai_optimization! if @listing.draft? || @listing.analyzing?
    @listing.update_columns(status: Listing.statuses[:optimized], optimized_at: 25.hours.ago)
    if @listing.auto_publish_if_expired!
      redirect_to @listing, notice: "⏱️ SLA Zaman Kuralı Tetiklendi: 24 saatlik süre aşımı simüle edildi ve araç otomatik olarak YAYINA ALINDI (Auto-Published)!"
    else
      redirect_to @listing, alert: "Otomatik yayınlama koşulu sağlanamadı."
    end
  end

  def capture
  end

  def capture_new
    @listing = Listing.order(created_at: :desc).first || Listing.new(
      title: "Yeni Çekim Aracı",
      brand: "BMW",
      model_name: "320i M Sport",
      year: 2024,
      color: "Mineral Gri"
    )
    render :capture
  end

  def download_capture_zip
    @listing ||= Listing.find_by(id: params[:id]) || Listing.order(created_at: :desc).first || Listing.new(
      title: "AutoAorta Araç",
      brand: "AutoAorta"
    )

    frames_param = params[:frames]
    frames_data = if frames_param.is_a?(String)
      JSON.parse(frames_param) rescue []
    elsif frames_param.is_a?(Array)
      frames_param
    else
      []
    end

    zip_data = build_capture_zip(@listing, frames_data)
    brand_param = @listing.brand.to_s.parameterize.presence || "vehicle"

    send_data zip_data,
              filename: "auto_aorta_#{brand_param}_capture_108_frames.zip",
              type: "application/zip",
              disposition: "attachment"
  end

  def destroy
    @listing.destroy
    redirect_to listings_path, notice: "İlan başarıyla silindi."
  end

  private

  def build_capture_zip(listing, frames_data)
    require "zip"

    rings_def = [
      { name: "düşük", label: "Düşük Seviye (Tampon / Jant)", sectors: 36 },
      { name: "orta", label: "Orta Seviye (Far / Gövde)", sectors: 36 },
      { name: "yüksek", label: "Yüksek Seviye (Tavan / Omuz)", sectors: 36 }
    ]

    final_frames = []
    if frames_data.present? && frames_data.any?
      frames_data.each_with_index do |f, idx|
        ring_name = f[:ring] || f["ring"] || rings_def[(idx / 36) % 3][:name]
        sector_num = (f[:sector] || f["sector"] || (idx % 36) + 1).to_i
        final_frames << {
          index: idx + 1,
          ring: ring_name,
          sector: sector_num,
          filename: f[:filename] || f["filename"] || sprintf("frame_%03d_halka_%s_sektor_%02d.jpg", idx + 1, ring_name, sector_num),
          timestamp: f[:timestamp] || f["timestamp"] || Time.current.iso8601,
          data: f[:data] || f["data"]
        }
      end
    else
      frame_idx = 1
      rings_def.each do |ring_info|
        (1..36).each do |sec|
          final_frames << {
            index: frame_idx,
            ring: ring_info[:name],
            sector: sec,
            filename: sprintf("frame_%03d_halka_%s_sektor_%02d.jpg", frame_idx, ring_info[:name], sec),
            timestamp: Time.current.iso8601
          }
          frame_idx += 1
        end
      end
    end

    metadata = {
      listing_id: listing&.id,
      title: listing&.title || "AutoAorta 3D Fotogrametri Çekim Seti",
      brand: listing&.brand,
      model_name: listing&.model_name.to_s,
      total_frames: final_frames.size,
      rings: rings_def,
      captured_at: Time.current.iso8601,
      frames: final_frames.map { |f| f.except(:data, "data") }
    }

    sample_jpeg = find_sample_vehicle_jpeg(listing)

    stringio = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry("metadata.json")
      zio.write(JSON.pretty_generate(metadata))

      final_frames.each do |frame|
        filename = frame[:filename]
        data_str = frame[:data]

        image_bytes = if data_str.present?
          decode_base64_image(data_str)
        else
          sample_jpeg
        end

        zio.put_next_entry("images/#{filename}")
        zio.write(image_bytes)
      end
    end

    stringio.rewind
    stringio.read
  end

  def decode_base64_image(data_str)
    if data_str.include?(",")
      Base64.decode64(data_str.split(",", 2)[1])
    else
      Base64.decode64(data_str)
    end
  rescue StandardError
    minimal_jpeg_bytes
  end

  def find_sample_vehicle_jpeg(listing)
    if listing&.photos&.attached? && listing.photos.first.present?
      begin
        return listing.photos.first.download
      rescue StandardError
      end
    end

    bmw_img = Rails.root.join("public", "vehicles", "bmw", "01_front_three_quarter.jpg")
    return File.binread(bmw_img) if File.exist?(bmw_img)

    minimal_jpeg_bytes
  end

  def minimal_jpeg_bytes
    [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48,
      0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08,
      0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20,
      0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27,
      0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01,
      0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04,
      0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
      0x00, 0xBF, 0x00, 0xFF, 0xD9
    ].pack("C*")
  end

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def listing_params
    params.require(:listing).permit(
      :title, :brand, :model_name, :year, :price, :mileage,
      :fuel_type, :transmission, :description,
      :color, :body_type, :tramer, :expertise, :dealer_phone, :dealer_name,
      photos: []
    )
  end
end
