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
