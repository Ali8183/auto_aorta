require "open-uri"
require "stringio"

puts "== Seeding AutoAorta AI Enterprise Fleet Database =="

Listing.destroy_all

# Minimal valid fallback JPEG bytes in case of offline/network limits
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

def fetch_image_io(url)
  io = nil
  begin
    URI.open(url, "User-Agent" => "AutoAortaAI/2.0 (fleet_bot@autoaorta.org)", read_timeout: 8, open_timeout: 5) do |f|
      io = StringIO.new(f.read)
    end
  rescue => e
    io = StringIO.new(FALLBACK_JPEG)
  end
  io
end

fleet_specs = [
  # 1. Sedan: BMW 320i M Sport
  {
    attributes: {
      title: "2023 BMW 320i M Sport Harman Kardon Head-Up AI Studio",
      brand: "BMW",
      model_name: "320i Sedan M Sport",
      year: 2023,
      price: 2_950_000,
      mileage: 18_400,
      fuel_type: "Benzin",
      transmission: "Otomatik",
      color: "Mineral Metalik Gri",
      body_type: "Sedan",
      expertise: "Hatasız / Boyasız / Değişensiz",
      tramer: "Hasar Kaydı Yok / 0 TL",
      dealer_name: "AutoAorta Premier Fleet",
      dealer_phone: "+90 532 500 40 30",
      description: <<~DESC
        Carvana & Impel.io Merchandising Studio standardında hazırlanmış BMW 320i M Sport.
        - M Aerodinamik Paket & 19" M Çift Kollu Stil Jantlar
        - Harman Kardon Surround Ses Sistemi & Head-Up Display
        - Canlı 360° Etkileşimli Sanal Tur & AI Stüdyo Onaylı 45° Hero Vitrin Görseli
      DESC
    },
    photos: [
      { filename: "01_bmw_front_three_quarter.jpg", url: "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=1200&q=80" },
      { filename: "02_bmw_front.jpg",               url: "https://images.unsplash.com/photo-1617531653332-bd46c24f2068?auto=format&fit=crop&w=1200&q=80" },
      { filename: "03_bmw_side.jpg",                url: "https://images.unsplash.com/photo-1580273916550-e323be2ae537?auto=format&fit=crop&w=1200&q=80" },
      { filename: "04_bmw_rear_three_quarter.jpg",  url: "https://images.unsplash.com/photo-1556189250-72ba954cfc2b?auto=format&fit=crop&w=1200&q=80" },
      { filename: "05_bmw_rear.jpg",                url: "https://images.unsplash.com/photo-1607853202273-797f1c22a38e?auto=format&fit=crop&w=1200&q=80" },
      { filename: "06_bmw_interior.jpg",            url: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=1200&q=80" }
    ]
  },
  # 2. Electric: Tesla Model 3 Long Range
  {
    attributes: {
      title: "2024 Tesla Model 3 Long Range Dual Motor AWD Otopilot",
      brand: "Tesla",
      model_name: "Model 3 Long Range",
      year: 2024,
      price: 2_450_000,
      mileage: 12_500,
      fuel_type: "Elektrik",
      transmission: "Otomatik",
      color: "İnci Beyazı (Multi-Coat)",
      body_type: "Sedan",
      expertise: "Hatasız / Çiziksiz / Boyasız",
      tramer: "Tramer Kaydı Bulunmamaktadır (0 TL)",
      dealer_name: "AutoAorta EV Selection",
      dealer_phone: "+90 533 400 50 60",
      description: <<~DESC
        Yeni Nesil Highland Kasa Tesla Model 3 Long Range Dual Motor AWD.
        - Çift Motorlu Dört Çeker (498 HP) & 629 km WLTP Menzil
        - Otopilot & 15.4" Dokunmatik Merkezi Ekran & Arka Yolcu Ekranı
        - Isı Pompalı Termal Yönetim & Cam Tavan Akustik İzolasyon
        - AutoAorta 360° Döner Vitrin & Stüdyo Onaylı Hero Shot
      DESC
    },
    photos: [
      { filename: "01_tesla_front_three_quarter.jpg", url: "https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=1200&q=80" },
      { filename: "02_tesla_front.jpg",               url: "https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&w=1200&q=80" },
      { filename: "03_tesla_side.jpg",                url: "https://images.unsplash.com/photo-1536700503339-1e4b06520771?auto=format&fit=crop&w=1200&q=80" },
      { filename: "04_tesla_rear_three_quarter.jpg",  url: "https://images.unsplash.com/photo-1619767886558-efdc259cde1a?auto=format&fit=crop&w=1200&q=80" },
      { filename: "05_tesla_rear.jpg",                url: "https://images.unsplash.com/photo-1571987502227-9231b837d92a?auto=format&fit=crop&w=1200&q=80" },
      { filename: "06_tesla_interior.jpg",            url: "https://images.unsplash.com/photo-1620891549027-942fdc95d3f5?auto=format&fit=crop&w=1200&q=80" }
    ]
  },
  # 3. SUV / Sport: Porsche Macan GTS
  {
    attributes: {
      title: "2023 Porsche Macan GTS 2.9 V6 BiTurbo Sport Chrono Panoramik",
      brand: "Porsche",
      model_name: "Macan GTS PDK",
      year: 2023,
      price: 6_850_000,
      mileage: 24_000,
      fuel_type: "Benzin",
      transmission: "Otomatik",
      color: "Volcano Metalik Gri",
      body_type: "SUV",
      expertise: "Hatasız / Boyasız / Ön Bölge PPF Kaplama",
      tramer: "Hasarsız / 0 TL",
      dealer_name: "AutoAorta Exclusive Motors",
      dealer_phone: "+90 535 700 80 90",
      description: <<~DESC
        Porsche Macan GTS 440 HP 2.9 Litre V6 BiTurbo Motor.
        - Sport Chrono Paketi & Porsche Aktif Süspansiyon Yönetimi (PASM)
        - 21" RS Spyder Design Parlak Siyah Jantlar & Spor Egzoz Sistemi
        - Bose Surround Ses Sistemi & Panoramik Açılır Cam Tavan
        - Impel/Carvana AI Onaylı 360° Sanal Tur & 45° Altın Açı Vitrin
      DESC
    },
    photos: [
      { filename: "01_porsche_front_three_quarter.jpg", url: "https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?auto=format&fit=crop&w=1200&q=80" },
      { filename: "02_porsche_front.jpg",               url: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80" },
      { filename: "03_porsche_side.jpg",                url: "https://images.unsplash.com/photo-1580274455191-1c62238fa333?auto=format&fit=crop&w=1200&q=80" },
      { filename: "04_porsche_rear_three_quarter.jpg",  url: "https://images.unsplash.com/photo-1611821064430-0d40291d0f0b?auto=format&fit=crop&w=1200&q=80" },
      { filename: "05_porsche_rear.jpg",                url: "https://images.unsplash.com/photo-1544636331-e26879cd4d9b?auto=format&fit=crop&w=1200&q=80" },
      { filename: "06_porsche_interior.jpg",            url: "https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=1200&q=80" }
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

  puts "  Running AutoAorta AI Vision Optimization..."
  listing.start_ai_optimization!
  puts "  ✓ Optimized! Hero photo ID: #{listing.hero_photo_id}, 360 Spin frames: #{listing.spin_photos.size}"
end

puts "\n== Fleet Seeding Completed Successfully! =="
puts "Total Listings: #{Listing.count}"
Listing.all.each do |l|
  puts "- #{l.title} (Price: #{l.price} ₺, Status: #{l.status}, Photos: #{l.photos.count})"
end
