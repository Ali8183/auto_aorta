require "test_helper"

class DefectTest < ActiveSupport::TestCase
  test "belongs to listing" do
    listing = Listing.create!(
      title: "Test Car",
      brand: "Porsche",
      model_name: "Taycan",
      year: 2024,
      price: 5_000_000
    )

    defect = Defect.create!(
      listing: listing,
      title: "Sol Arka Çamurluk Vernik",
      part_name: "Sol Arka Çamurluk",
      micron_value: 165,
      defect_type: "Lokal Boya"
    )

    assert_equal listing, defect.listing
    assert_equal 165, defect.micron_value
  end
end
