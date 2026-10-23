require "test_helper"

module Api
  module V1
    class MerchandisingControllerTest < ActionDispatch::IntegrationTest
      def setup
        @listing = Listing.create!(
          title: "2023 BMW 320i M Sport",
          brand: "BMW",
          model_name: "320i Sedan",
          year: 2023,
          price: 2_950_000,
          mileage: 18_400,
          fuel_type: "Benzin",
          transmission: "Otomatik",
          color: "Mineral Gri",
          body_type: "Sedan",
          expertise: "Hatasız",
          tramer: "0 TL"
        )

        @listing.photos.attach(
          io: StringIO.new("sample_image_data_front_3_4"),
          filename: "01_front_three_quarter.jpg",
          content_type: "image/jpeg"
        )
        @listing.start_ai_optimization!
      end

      test "POST /api/v1/merchandise creates listing and returns AI optimization JSON" do
        file_io = Rack::Test::UploadedFile.new(StringIO.new("mock_jpeg_bytes"), "image/jpeg", original_filename: "01_hero_front_three_quarter.jpg")

        assert_difference("Listing.count", 1) do
          post api_v1_merchandise_index_url, params: {
            title: "2024 Tesla Model Y Long Range",
            brand: "Tesla",
            model_name: "Model Y",
            year: 2024,
            price: 2_600_000,
            mileage: 15_000,
            fuel_type: "Elektrik",
            transmission: "Otomatik",
            color: "Solid Black",
            body_type: "SUV",
            expertise: "Hatasız",
            tramer: "0 TL",
            photos: [ file_io ]
          }
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "success", json["status"]
        assert_equal "Tesla", json["brand"]
        assert_equal "Model Y", json["model_name"]
        assert_not_nil json["hero_shot"]
        assert_not_nil json["embed_url"]
        assert_includes json["embed_iframe_code"], "<iframe src="
        assert_not_nil json["stats_projection"]
        assert_equal "+170%", json["stats_projection"]["ctr_increase"]
      end

      test "POST /api/v1/merchandise returns 422 for invalid params" do
        assert_no_difference("Listing.count") do
          post api_v1_merchandise_index_url, params: {
            brand: "BMW" # Missing title, model_name, year, price
          }
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "error", json["status"]
        assert json["errors"].any?
      end

      test "GET /api/v1/merchandise/:id returns full merchandise data" do
        get api_v1_merchandise_url(@listing)
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "success", json["status"]
        assert_equal @listing.id, json["listing_id"]
        assert_equal "BMW", json["brand"]
        assert_not_nil json["hero_shot"]
        assert_equal "front_three_quarter", json["hero_shot"]["detected_angle"]
        assert_equal embed_listing_url(@listing), json["embed_url"]
      end

      test "GET /api/v1/merchandise/:id returns 404 for unknown id" do
        get api_v1_merchandise_url(id: 999999)
        assert_response :not_found
        json = JSON.parse(response.body)
        assert_equal "error", json["status"]
      end
    end
  end
end
