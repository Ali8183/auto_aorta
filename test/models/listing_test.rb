require "test_helper"

class ListingTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @listing = Listing.create!(
      title: "2023 BMW 320i M Sport Stüdyo Çekim",
      brand: "BMW",
      model_name: "320i Sedan",
      year: 2023,
      price: 2_850_000,
      mileage: 22_000,
      fuel_type: "Benzin",
      transmission: "Otomatik",
      description: "Hatasız, boyasız, stüdyo çekimli BMW 320i."
    )

    # Attach dummy test images representing exterior & interior angles
    @listing.photos.attach(
      io: StringIO.new("front_three_quarter_bytes"),
      filename: "bmw_front_three_quarter.jpg",
      content_type: "image/jpeg"
    )
    @listing.photos.attach(
      io: StringIO.new("front_bytes"),
      filename: "bmw_front.jpg",
      content_type: "image/jpeg"
    )
    @listing.photos.attach(
      io: StringIO.new("side_bytes"),
      filename: "bmw_side.jpg",
      content_type: "image/jpeg"
    )
    @listing.photos.attach(
      io: StringIO.new("interior_bytes"),
      filename: "bmw_interior.jpg",
      content_type: "image/jpeg"
    )
  end

  def teardown
    travel_back
  end

  test "initial status is draft" do
    assert @listing.draft?
    assert_nil @listing.optimized_at
    assert_nil @listing.auto_published_at
  end

  test "manual publish! transitions status to published" do
    @listing.publish!
    assert @listing.published?
  end

  test "start_ai_optimization! runs vision analysis, sets optimized status and optimized_at" do
    freeze_time do
      @listing.start_ai_optimization!

      assert @listing.optimized?
      assert_equal Time.current, @listing.optimized_at
      assert_equal 4, @listing.photo_analyses.count

      # Verify Front 3/4 photo was selected as Hero Shot
      hero_analysis = @listing.hero_photo_analysis
      assert_not_nil hero_analysis
      assert_equal "front_three_quarter", hero_analysis.detected_angle
      assert hero_analysis.is_hero_candidate?
      assert_equal 98, hero_analysis.quality_score
      assert_equal @listing.photos.first.id, @listing.hero_photo_id

      # Verify spin photos sequence excludes interior photo
      spin_photos = @listing.spin_photos
      assert_equal 3, spin_photos.size # front_three_quarter (1), front (2), side (3)
    end
  end

  test "24-hour SLA time rule: does not auto-publish when under 24 hours" do
    reference_time = Time.zone.parse("2026-10-23 10:00:00")
    travel_to reference_time

    @listing.start_ai_optimization!
    assert @listing.optimized?

    # Travel 23 hours into the future (still within 24h SLA)
    travel 23.hours
    result = @listing.auto_publish_if_expired!

    assert_not result
    assert @listing.reload.optimized?
    assert_not @listing.published?
    assert_nil @listing.auto_published_at
  end

  test "24-hour SLA time rule: automatically publishes when 24 hours have elapsed using travel_to" do
    initial_time = Time.zone.parse("2026-10-23 12:00:00")
    travel_to initial_time

    @listing.start_ai_optimization!
    assert @listing.optimized?
    assert_equal initial_time, @listing.optimized_at

    # Travel past 24 hours (24 hours and 1 minute)
    travel 24.hours + 1.minute
    result = @listing.auto_publish_if_expired!

    assert result, "auto_publish_if_expired! should return true after 24 hours"
    assert @listing.reload.published?, "Listing status should be transitioned to 'published'"
    assert_not_nil @listing.auto_published_at, "auto_published_at must be populated"
    assert_equal Time.current, @listing.auto_published_at
  end

  test "auto_publish_if_expired! does nothing if listing is not optimized" do
    assert @listing.draft?

    travel 48.hours
    assert_not @listing.auto_publish_if_expired!
    assert @listing.draft?
  end

  test "validate_vehicle_consistency! does not claim color verification in heuristic mode and still excludes mismatched photos" do
    service = VehicleVisionService.new(@listing)
    service.call
    report = service.validate_vehicle_consistency!

    assert report[:valid]
    assert_not report[:verified], "Without a Vision API result the color check must not be reported as performed"
    assert_nil report[:message]
    @listing.photo_analyses.each do |analysis|
      assert_includes analysis.notes, "Heuristik mod (dosya adı tahmini)"
      assert_not_includes analysis.notes, "AI Bütünlük Kontrolü:"
      assert_not_includes analysis.notes, "AI Vision Studio"
    end

    # Attach an anomalous different vehicle/color photo and verify it is excluded from the 360° spin sequence
    @listing.photos.attach(
      io: StringIO.new("anomalous_bytes"),
      filename: "porsche_red_rear.jpg",
      content_type: "image/jpeg"
    )
    service.call

    anomalous_analysis = @listing.photo_analyses.order(:id).last
    assert_equal 0, anomalous_analysis.spin_order
    assert_not anomalous_analysis.is_hero_candidate?
  end

  test "validate_vehicle_consistency! writes confirmation only when a real Vision color check ran" do
    service = VehicleVisionService.new(@listing)
    photos = @listing.photos.to_a
    angles = %w[front_three_quarter front side interior]
    colors = [ "Mineral Grey", "Mineral Grey", "Red", nil ]

    items = photos.each_with_index.map do |photo, i|
      analysis = @listing.photo_analyses.build(blob_id: photo.blob_id, detected_angle: angles[i], quality_score: 90, spin_order: i < 3 ? i + 1 : 0)
      { photo: photo, analysis: analysis, spec: { source: :llm, color: colors[i], make: "BMW" } }
    end

    report = service.validate_vehicle_consistency!(items)

    assert report[:verified]
    assert_equal 1, report[:anomaly_count]
    assert_includes report[:message], "AI Bütünlük Kontrolü: 2 dış görselin tamamı aynı gövde rengine (Mineral Grey)"
    assert_equal 0, items[2][:analysis].spin_order
  end
end
