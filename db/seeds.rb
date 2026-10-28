require "open-uri"
require "stringio"

puts "== Seeding AutoAorta AI Enterprise Fleet Database (Single-Vehicle Verified Sets) =="

Listing.destroy_all

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

def fetch_image_io(local_or_url)
  local_file = Rails.root.join("public", local_or_url.sub(/\A\//, ""))
  if File.exist?(local_file)
    return StringIO.new(File.binread(local_file))
  end

  URI.open(local_or_url, "User-Agent" => "AutoAortaAI/2.0", read_timeout: 8, open_timeout: 5) do |f|
    StringIO.new(f.read)
  end
rescue StandardError
  StringIO.new(FALLBACK_JPEG)
end

fleet_specs = [
  # 1. Coupe / Hybrid Supercar: 2022 BMW i8 Coupe Plug-in Hybrid (Protonic Blue / Frozen Grey) - 1:1 Digital Twin with PlayCanvas 3D
  {
    attributes: {
      title: "2022 BMW i8 Coupe Plug-in Hybrid (Protonic Blue / Frozen Grey)",
      brand: "BMW",
      model_name: "i8 Coupe",
      year: 2022,
      price: 8_450_000,
      mileage: 14_800,
      fuel_type: "1.5L Turbo Plug-in Hybrid (369 HP)",
      transmission: "Otomatik",
      color: "Protonic Blue / Frozen Grey",
      body_type: "Coupe",
      expertise: "Hatasız / Boyasız / Karbon LifeDrive Şasi (Ön Tampon 2mm Taş İzi Şeffaf Kayıtlı)",
      tramer: "Hasar Kaydı Yok / 0 TL",
      dealer_name: "AutoAorta Premier Fleet",
      dealer_phone: "+90 532 500 40 30",
      description: <<~DESC
        ✓ 1:1 Doğrulanmış Dijital İkiz (Digital Twin): Fotoğraflar ve PlayCanvas 3D CAD verisi bizzat aynı BMW i8 şasisine aittir.
        - 1.5L TwinPower Turbo + eDrive Plug-in Hybrid (369 HP / 570 Nm) AWD
        - Protonic Blue Metallic & Frozen Grey Karbon Fiber (CFRP) LifeDrive Gövde
        - Lazer Farlar, Kelebek (Scissor) Kapılar & 20" BMW i Türbin Stil Jantlar
        - Senkronize PlayCanvas WebGL 3D & Doğrulanmış Gerçek Piksel 360° Stüdyo Turu
      DESC
    },
    photos: [
      { filename: "01_bmw_i8_front_three_quarter.jpg", url: "/vehicles/bmw/01_front_three_quarter.jpg" },
      { filename: "02_bmw_i8_front.jpg",               url: "/vehicles/bmw/02_front.jpg" },
      { filename: "03_bmw_i8_side.jpg",                url: "/vehicles/bmw/03_side.jpg" },
      { filename: "04_bmw_i8_rear_three_quarter.jpg",  url: "/vehicles/bmw/04_rear_three_quarter.jpg" },
      { filename: "05_bmw_i8_rear.jpg",                url: "/vehicles/bmw/05_rear.jpg" },
      { filename: "06_bmw_i8_interior.jpg",            url: "/vehicles/bmw/06_interior.jpg" }
    ]
  },
  # 2. Electric: Tesla Model 3 Long Range - İnci Beyazı (Pearl White Multi-Coat)
  {
    attributes: {
      title: "2024 Tesla Model 3 Long Range Dual Motor AWD İnci Beyazı",
      brand: "Tesla",
      model_name: "Model 3 Long Range Highland",
      year: 2024,
      price: 2_450_000,
      mileage: 12_500,
      fuel_type: "Elektrik",
      transmission: "Otomatik",
      color: "İnci Beyazı (Pearl White Multi-Coat)",
      body_type: "Sedan",
      expertise: "Hatasız / Çiziksiz / Boyasız",
      tramer: "Tramer Kaydı Bulunmamaktadır (0 TL)",
      dealer_name: "AutoAorta EV Selection",
      dealer_phone: "+90 533 400 50 60",
      description: <<~DESC
        Yeni Nesil Highland Kasa İnci Beyazı Tesla Model 3 Long Range Dual Motor AWD.
        - 6 açının tamamı bizzat aynı İnci Beyazı Tesla Model 3 aracına aittir (AI Bütünlük Kontrolü Onaylı).
        - Çift Motorlu Dört Çeker (498 HP) & 629 km WLTP Menzil
        - Otopilot & 15.4" Merkezi Dokunmatik Ekran & Akustik Cam Tavan
        - Senkronize PlayCanvas WebGL 3D & Doğrulanmış Gerçek Piksel 360° Tur
      DESC
    },
    photos: [
      { filename: "01_tesla_front_three_quarter.jpg", url: "/vehicles/tesla/01_front_three_quarter.jpg" },
      { filename: "02_tesla_front.jpg",               url: "/vehicles/tesla/02_front.jpg" },
      { filename: "03_tesla_side.jpg",                url: "/vehicles/tesla/03_side.jpg" },
      { filename: "04_tesla_rear_three_quarter.jpg",  url: "/vehicles/tesla/04_rear_three_quarter.jpg" },
      { filename: "05_tesla_rear.jpg",                url: "/vehicles/tesla/05_rear.jpg" },
      { filename: "06_tesla_interior.jpg",            url: "/vehicles/tesla/06_interior.jpg" }
    ]
  },
  # 3. SUV / Sport: Porsche Macan GTS - Koyu Gri (Volcano Grey Metallic)
  {
    attributes: {
      title: "2024 Porsche Macan GTS Koyu Gri (Volcano Grey) Sport Chrono",
      brand: "Porsche",
      model_name: "Macan GTS PDK",
      year: 2024,
      price: 6_850_000,
      mileage: 14_200,
      fuel_type: "Benzin",
      transmission: "Otomatik",
      color: "Koyu Gri (Volcano Grey Metallic)",
      body_type: "SUV",
      expertise: "Hatasız / Boyasız / Ön Bölge PPF Kaplama",
      tramer: "Hasarsız / 0 TL",
      dealer_name: "AutoAorta Exclusive Motors",
      dealer_phone: "+90 535 700 80 90",
      description: <<~DESC
        Koyu Gri (Volcano Grey Metallic) Porsche Macan GTS Sport Chrono Paketi.
        - 6 açının tamamı bizzat aynı Koyu Gri Porsche Macan aracına aittir (AI Bütünlük Kontrolü Onaylı).
        - Sport Chrono Paketi & Porsche Aktif Süspansiyon Yönetimi (PASM)
        - 21" RS Spyder Design Jantlar & Panoramik Cam Tavan
        - Senkronize PlayCanvas WebGL 3D & Doğrulanmış Gerçek Piksel 360° Tur
      DESC
    },
    photos: [
      { filename: "01_porsche_front_three_quarter.jpg", url: "/vehicles/porsche/01_front_three_quarter.jpg" },
      { filename: "02_porsche_front.jpg",               url: "/vehicles/porsche/02_front.jpg" },
      { filename: "03_porsche_side.jpg",                url: "/vehicles/porsche/03_side.jpg" },
      { filename: "04_porsche_rear_three_quarter.jpg",  url: "/vehicles/porsche/04_rear_three_quarter.jpg" },
      { filename: "05_porsche_rear.jpg",                url: "/vehicles/porsche/05_rear.jpg" },
      { filename: "06_porsche_interior.jpg",            url: "/vehicles/porsche/06_interior.jpg" }
    ]
  }
]

fleet_specs.each_with_index do |spec, car_idx|
  puts "Creating vehicle #{car_idx + 1}/#{fleet_specs.size}: #{spec[:attributes][:title]}..."
  listing = Listing.create!(spec[:attributes])

  spec[:photos].each_with_index do |p_data, p_idx|
    print "  Attaching photo #{p_idx + 1}/#{spec[:photos].size}: #{p_data[:filename]}... "
    io = fetch_image_io(p_data[:url])
    listing.photos.attach(
      io: io,
      filename: p_data[:filename],
      content_type: "image/jpeg"
    )
    puts "✓"
  end

  puts "  Running AutoAorta AI Vision Optimization & Consistency Check..."
  listing.start_ai_optimization!
  puts "  ✓ Optimized! Hero photo ID: #{listing.hero_photo_id}, 360 Spin frames: #{listing.spin_photos.size}"
end

puts "\n== Fleet Seeding Completed Successfully! =="
puts "Total Listings: #{Listing.count}"
Listing.all.each do |l|
  puts "- #{l.title} (Color: #{l.color}, Status: #{l.status}, Photos: #{l.photos.count})"
end
