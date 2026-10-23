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
      { filename: "01_bmw_front_three_quarter.jpg", url: "https://upload.wikimedia.org/wikipedia/commons/0/03/2019_BMW_320d_xDrive_M_Sport_2.0_Front.jpg" },
      { filename: "02_bmw_front.jpg",               url: "https://upload.wikimedia.org/wikipedia/commons/a/ab/2019_Brilliance-BMW_325i_%28front%29.jpg" },
      { filename: "03_bmw_side.jpg",                url: "https://upload.wikimedia.org/wikipedia/commons/3/38/BMW_3-Series_%2852823659926%29.jpg" },
      { filename: "04_bmw_rear_three_quarter.jpg",  url: "https://upload.wikimedia.org/wikipedia/commons/e/eb/2019_BMW_320d_xDrive_M_Sport_2.0_Rear.jpg" },
      { filename: "05_bmw_rear.jpg",                url: "https://upload.wikimedia.org/wikipedia/commons/b/b9/2019_Brilliance-BMW_325i_%28rear%29.jpg" },
      { filename: "06_bmw_interior.jpg",            url: "https://upload.wikimedia.org/wikipedia/commons/6/63/2023_BMW_318i_dashboard.jpg" }
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
      { filename: "01_tesla_front_three_quarter.jpg", url: "https://upload.wikimedia.org/wikipedia/commons/9/91/2019_Tesla_Model_3_Performance_AWD_Front.jpg" },
      { filename: "02_tesla_front.jpg",               url: "https://upload.wikimedia.org/wikipedia/commons/4/4b/2018_Tesla_Model_3_front_view_%281%29.jpg" },
      { filename: "03_tesla_side.jpg",                url: "https://upload.wikimedia.org/wikipedia/commons/0/0c/2018_Tesla_Model_3_Long_Range_Dual_Motor_side.jpg" },
      { filename: "04_tesla_rear_three_quarter.jpg",  url: "https://upload.wikimedia.org/wikipedia/commons/1/14/2018_Tesla_Model_3_rear_view_%281%29.jpg" },
      { filename: "05_tesla_rear.jpg",                url: "https://upload.wikimedia.org/wikipedia/commons/e/e2/2018_Tesla_Model_3_Dual_Motor_rear.jpg" },
      { filename: "06_tesla_interior.jpg",            url: "https://upload.wikimedia.org/wikipedia/commons/6/67/2018_Tesla_Model_3_interior.jpg" }
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
      { filename: "01_porsche_front_three_quarter.jpg", url: "https://upload.wikimedia.org/wikipedia/commons/9/93/Porsche_Macan_GTS_%2895B%29_IMG_1427.jpg" },
      { filename: "02_porsche_front.jpg",               url: "https://upload.wikimedia.org/wikipedia/commons/e/e5/2015_Porsche_Macan_S_Diesel_3.0_Front.jpg" },
      { filename: "03_porsche_side.jpg",                url: "https://upload.wikimedia.org/wikipedia/commons/a/af/Porsche_Macan_GTS_Gen_3_side.jpg" },
      { filename: "04_porsche_rear_three_quarter.jpg",  url: "https://upload.wikimedia.org/wikipedia/commons/d/d7/Porsche_Macan_GTS_%2895B%29_IMG_1428.jpg" },
      { filename: "05_porsche_rear.jpg",                url: "https://upload.wikimedia.org/wikipedia/commons/2/23/2015_Porsche_Macan_S_Diesel_3.0_Rear.jpg" },
      { filename: "06_porsche_interior.jpg",            url: "https://upload.wikimedia.org/wikipedia/commons/c/c5/Porsche_Macan_Turbo_%2895B%29_%E2%80%93_Cockpit%2C_28._Februar_2015%2C_D%C3%BCsseldorf.jpg" }
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
