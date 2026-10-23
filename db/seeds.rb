require "open-uri"
require "stringio"

puts "== Seeding AutoAorta AI Merchandising Database =="

Listing.destroy_all

puts "Creating BMW 3 Series Listing..."
listing = Listing.create!(
  title: "2023 BMW 320i M Sport Harman Kardon Head-Up AI Studio",
  brand: "BMW",
  model_name: "320i Sedan M Sport",
  year: 2023,
  price: 2_950_000,
  mileage: 18_400,
  fuel_type: "Benzin",
  transmission: "Otomatik",
  description: <<~DESC
    Impel.io & Phyron AI Merchandising Studio standardında hazırlanmış BMW 320i M Sport.
    - Boyasız, Değişensiz, Tramer Kayıtsız
    - M Aerodinamik Paket & 19" M Çift Kollu Stil Jantlar
    - Harman Kardon Surround Ses Sistemi & Head-Up Display
    - BMW Live Cockpit Professional & Kablosuz Akıllı Telefon Şarjı
    - 360° Etkileşimli Sanal Tur & AI Stüdyo Onaylı 45° Hero Vitrin Görseli
  DESC
)

photos_data = [
  {
    filename: "01_bmw_front_three_quarter.jpg",
    url: "https://upload.wikimedia.org/wikipedia/commons/0/03/2019_BMW_320d_xDrive_M_Sport_2.0_Front.jpg",
    angle_label: "Ön 3/4 Vitrin Açısı"
  },
  {
    filename: "02_bmw_front.jpg",
    url: "https://upload.wikimedia.org/wikipedia/commons/a/ab/2019_Brilliance-BMW_325i_%28front%29.jpg",
    angle_label: "Ön Cephe (Tam)"
  },
  {
    filename: "03_bmw_side.jpg",
    url: "https://upload.wikimedia.org/wikipedia/commons/3/38/BMW_3-Series_%2852823659926%29.jpg",
    angle_label: "Yan Profil"
  },
  {
    filename: "04_bmw_rear_three_quarter.jpg",
    url: "https://upload.wikimedia.org/wikipedia/commons/e/eb/2019_BMW_320d_xDrive_M_Sport_2.0_Rear.jpg",
    angle_label: "Arka 3/4 Açılı"
  },
  {
    filename: "05_bmw_rear.jpg",
    url: "https://upload.wikimedia.org/wikipedia/commons/b/b9/2019_Brilliance-BMW_325i_%28rear%29.jpg",
    angle_label: "Arka Cephe"
  },
  {
    filename: "06_bmw_interior.jpg",
    url: "https://upload.wikimedia.org/wikipedia/commons/6/63/2023_BMW_318i_dashboard.jpg",
    angle_label: "İç Mekan / Kokpit"
  }
]

# Minimal valid fallback JPEG bytes in case of offline/network error
FALLBACK_JPEG = [
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
].pack("C*").freeze

photos_data.each_with_index do |item, idx|
  puts "Downloading photo #{idx + 1}/#{photos_data.size}: #{item[:filename]} (#{item[:angle_label]})..."
  io = nil
  begin
    URI.open(item[:url], "User-Agent" => "AutoAortaAI/1.0 (academic_bot@autoaorta.org)", read_timeout: 15) do |f|
      io = StringIO.new(f.read)
    end
  rescue => e
    puts "  [Notice] Wikimedia fetch failed (#{e.message}), using fallback image buffer."
    io = StringIO.new(FALLBACK_JPEG)
  end

  listing.photos.attach(
    io: io,
    filename: item[:filename],
    content_type: "image/jpeg"
  )
end

puts "Running AI Vision Studio Optimization on Listing..."
listing.start_ai_optimization!

puts "\n== Seed Summary =="
puts "Listing: #{listing.title}"
puts "Status: #{listing.status}"
puts "Optimized At: #{listing.optimized_at}"
puts "Attached Photos: #{listing.photos.count}"
puts "Photo Analyses Generated: #{listing.photo_analyses.count}"
puts "Hero Photo ID: #{listing.hero_photo_id}"
puts "Hero Candidate Analysis: #{listing.hero_photo_analysis&.detected_angle} (Score: #{listing.hero_photo_analysis&.quality_score}/100)"
puts "360 Spin Sequence Photos: #{listing.spin_photos.count}"
puts "== Seeding Complete! =="
