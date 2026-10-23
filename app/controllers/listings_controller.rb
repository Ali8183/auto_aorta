class ListingsController < ApplicationController
  before_action :set_listing, only: %i[show destroy optimize publish simulate_time_lapse]

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
    if @listing.optimized?
      # Simulate that 25 hours passed since optimization
      @listing.update_columns(optimized_at: 25.hours.ago)
      if @listing.auto_publish_if_expired!
        redirect_to @listing, notice: "⏱️ SLA Zaman Kuralı Tetiklendi: 24 saatlik süre aşımı simüle edildi ve araç otomatik olarak YAYINA ALINDI (Auto-Published)!"
      else
        redirect_to @listing, alert: "Otomatik yayınlama koşulu sağlanamadı."
      end
    elsif @listing.published?
      redirect_to @listing, alert: "İlan zaten yayında."
    else
      redirect_to @listing, alert: "SLA kuralı sadece 'Optimize Edildi' durumundaki ilanlar için geçerlidir. Lütfen önce AI Optimizasyonunu başlatın."
    end
  end

  def destroy
    @listing.destroy
    redirect_to listings_path, notice: "İlan başarıyla silindi."
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def listing_params
    params.require(:listing).permit(
      :title, :brand, :model_name, :year, :price, :mileage,
      :fuel_type, :transmission, :description, photos: []
    )
  end
end
