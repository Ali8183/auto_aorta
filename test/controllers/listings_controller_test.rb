require "test_helper"

class ListingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @listing = Listing.create!(
      title: "2023 BMW 320i M Sport",
      brand: "BMW",
      model_name: "320i Sedan",
      year: 2023,
      price: 2_850_000,
      mileage: 20_000,
      fuel_type: "Benzin",
      transmission: "Otomatik"
    )

    @listing.photos.attach(
      io: StringIO.new("sample_front_3_4"),
      filename: "01_front_three_quarter.jpg",
      content_type: "image/jpeg"
    )
    @listing.photos.attach(
      io: StringIO.new("sample_rear"),
      filename: "05_rear.jpg",
      content_type: "image/jpeg"
    )
  end

  test "should get index" do
    get listings_url
    assert_response :success
    assert_select "h1", /Araç Filosu|360° Vitrin/
  end

  test "should get show" do
    get listing_url(@listing)
    assert_response :success
    assert_select "h1", /#{@listing.title}/
    assert_select "#tab-btn-photo", /360° Doğrulanmış Fotoğraf Turu/
    assert_select "#tab-btn-guardrail", /Tüketici Güvenliği & Ekspertiz Kilidi/
    assert_select "#tab-btn-splat", false
    assert_select "#tab-panel-splat", false
    assert_select "#tab-btn-playcanvas", false
    assert_select "#tab-panel-photo:not(.hidden)"
    assert_select "#gaussian-splat-container", false
    assert_select "#carvana-inspection-card", false
    assert_no_match "gaussian-splats-3d", response.body
    assert_no_match "100% Real Pixels", response.body
    assert_no_match "Gerçek 3D Dijital İkiz", response.body
    assert_select "#inspection-demo-badge", /Örnek \/ Demo Veri/
    assert_match "Kaynak: Cox Automotive sektör araştırması; bu ilana özel ölçüm değildir.", response.body
    assert_match "160 / 160 Nokta Onaylandı (Demo)", response.body
    assert_match "Sıfır Halüsinasyon Güvencesi", response.body
  end

  test "should show 3D tab and GaussianSplats3D viewer when listing has splat" do
    @listing.splat.attach(
      io: StringIO.new("splat_test_bytes"),
      filename: "test_model.splat",
      content_type: "application/octet-stream"
    )

    get listing_url(@listing)
    assert_response :success
    assert_select "#tab-btn-splat", /3D Gaussian Splatting/
    assert_select "#tab-panel-splat"
    assert_select "#splat-viewer-container"
    assert_match "gaussian-splats-3d@0.4.4", response.body
    assert_match "GaussianSplats3D.Viewer", response.body
  end

  test "should get capture for listing" do
    get capture_listing_url(@listing)
    assert_response :success
    assert_select "[data-controller='vehicle-capture']"
    assert_match "Şimdi telefonu bir seviye alçalt/yükselt ve tekrar dön", response.body
    assert_match "Kareleri ZIP indir", response.body
    assert_match "Bulutlu Hava", response.body
    assert_match "Gölgesiz Alan", response.body
    assert_match "Yavaş Hareket", response.body
    assert_match "1.5-2 m", response.body
  end

  test "should get standalone capture" do
    get capture_url
    assert_response :success
    assert_select "[data-controller='vehicle-capture']"
  end

  test "should download capture zip via GET" do
    get download_capture_zip_listing_url(@listing)
    assert_response :success
    assert_equal "application/zip", response.content_type
    assert_includes response.headers["Content-Disposition"], "auto_aorta_bmw_capture_108_frames.zip"
  end

  test "should download capture zip via POST with client frames" do
    post download_capture_zip_listing_url(@listing), params: {
      frames: [
        {
          index: 1,
          ring: "düşük",
          sector: 1,
          filename: "frame_001_halka_1_dusuk_sektor_01.jpg",
          data: "data:image/jpeg;base64,/9j/4AAQSkZJRg=="
        }
      ].to_json
    }
    assert_response :success
    assert_equal "application/zip", response.content_type
  end

  test "should get new" do
    get new_listing_url
    assert_response :success
    assert_select "form"
  end

  test "should create listing" do
    assert_difference("Listing.count", 1) do
      post listings_url, params: {
        listing: {
          title: "Mercedes-Benz C200 AMG",
          brand: "Mercedes-Benz",
          model_name: "C200 Sedan",
          year: 2024,
          price: 3_450_000,
          mileage: 12_000,
          fuel_type: "Hibrit",
          transmission: "Otomatik",
          description: "Stüdyo çekimli test aracı."
        }
      }
    end

    assert_redirected_to listing_url(Listing.last)
  end

  test "should optimize listing" do
    post optimize_listing_url(@listing)
    assert_redirected_to listing_url(@listing)
    assert @listing.reload.optimized?
    assert_equal 2, @listing.photo_analyses.count
  end

  test "should publish listing" do
    post publish_listing_url(@listing)
    assert_redirected_to listing_url(@listing)
    assert @listing.reload.published?
  end

  test "should simulate time lapse and auto-publish when optimized" do
    @listing.start_ai_optimization!
    assert @listing.optimized?

    post simulate_time_lapse_listing_url(@listing)
    assert_redirected_to listing_url(@listing)
    assert @listing.reload.published?
    assert_not_nil @listing.auto_published_at
  end
end
