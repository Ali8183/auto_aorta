require "test_helper"

module Embed
  class ListingsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @listing = Listing.create!(
        title: "2023 BMW 320i M Sport",
        brand: "BMW",
        model_name: "320i Sedan",
        year: 2023,
        price: 2_950_000,
        mileage: 18_400,
        fuel_type: "Benzin",
        transmission: "Otomatik"
      )

      @listing.photos.attach(
        io: StringIO.new("sample_front_3_4"),
        filename: "01_front_three_quarter.jpg",
        content_type: "image/jpeg"
      )
      @listing.start_ai_optimization!
    end

    test "GET /embed/listings/:id renders standalone iframe widget" do
      get embed_listing_url(@listing)
      assert_response :success

      # Verify iframe security headers allow embedding
      assert_nil response.headers["X-Frame-Options"], "X-Frame-Options should be removed to allow iframes"
      assert_includes response.headers["Content-Security-Policy"].to_s, "frame-ancestors *", "CSP should allow frame-ancestors *"

      # Verify 360 spin widget markup
      assert_select "[data-controller='vehicle-spin']"
      assert_select "h2", /#{@listing.brand}/
    end
  end
end
