puts "== Seeding AutoAorta Official Certified Luxury Fleet =="

Defect.destroy_all if defined?(Defect)
PhotoAnalysis.destroy_all if defined?(PhotoAnalysis)
Listing.destroy_all

fleet_data = [
  # 1. 2024 Porsche Taycan 4S
  {
    attributes: {
      title: "2024 Porsche Taycan 4S Performance Plus AWD",
      brand: "Porsche",
      model_name: "Taycan 4S",
      year: 2024,
      price: 6_850_000,
      mileage: 18_500,
      fuel_type: "Elektrik",
      transmission: "Otomatik",
      color: "Volkan Grisi (Volcano Grey Metallic)",
      body_type: "Sedan",
      expertise: "Hatasız / Çiziksiz / Boyasız (Tüm Parçalar Orijinal)",
      tramer: "Tramer Kaydı Yok / 0 TL",
      dealer_name: "AutoAorta Maslak Atelier",
      dealer_phone: "+90 212 350 40 50",
      description: <<~DESC
        Doğuş Otomotiv çıkışlı, ilk sahibinden 2024 Porsche Taycan 4S.
        - Performance Plus 93.4 kWh Batarya Paketi (530 HP & 512 km WLTP)
        - 21" Mission E Tasarım Jantlar & Yüzey Kaplamalı Frenler (PSCB)
        - 14 Kademeli Hafızalı Konfor Koltuklar & Masaj / Soğutma Fonksiyonu
        - Panoramik Sabit Cam Tavan & Yolcu Ekranı (Passenger Display)
        - Porsche Dynamic Chassis Control Sport (PDCC Sport) & Arka Aks Yönlendirme
      DESC
    },
    photos: [
      { filename: "01_front_three_quarter.jpg", path: "public/vehicles/porsche/01_front_three_quarter.jpg" },
      { filename: "02_front.jpg",               path: "public/vehicles/porsche/02_front.jpg" },
      { filename: "03_side.jpg",                path: "public/vehicles/porsche/03_side.jpg" },
      { filename: "04_rear_three_quarter.jpg",  path: "public/vehicles/porsche/04_rear_three_quarter.jpg" },
      { filename: "05_rear.jpg",                path: "public/vehicles/porsche/05_rear.jpg" },
      { filename: "06_interior.jpg",            path: "public/vehicles/porsche/06_interior.jpg" }
    ],
    defects: [
      {
        part_name: "Ön Tampon",
        title: "Ön Tampon Plastik Aksam Taş İzi",
        micron_value: 115,
        defect_type: "Taş İzi",
        description: "115 Mikron Fabrika Boyası - Otoyol sürüşüne bağlı plastik tamponda 1mm yüzeysel taş izi. Kaporta sacında kusur yoktur.",
        position_x: 48.0,
        position_y: 65.0,
        frame_index: 0,
        severity: "minor"
      }
    ]
  },

  # 2. 2023 Audi e-tron GT quattro
  {
    attributes: {
      title: "2023 Audi e-tron GT quattro Karbon Paket",
      brand: "Audi",
      model_name: "e-tron GT quattro",
      year: 2023,
      price: 5_450_000,
      mileage: 24_000,
      fuel_type: "Elektrik",
      transmission: "Otomatik",
      color: "Mitik Siyah (Mythos Black Metallic)",
      body_type: "Coupe",
      expertise: "1 Parça Lokal Boya (Sol Arka Çamurluk Kordon Altı 165 Mikron)",
      tramer: "Tramer Kaydı Yok / 0 TL",
      dealer_name: "AutoAorta Maslak Atelier",
      dealer_phone: "+90 212 350 40 50",
      description: <<~DESC
        Yetkili servis bakımlı, Karbon Dış Görünüm Paketine sahip Audi e-tron GT quattro.
        - Çift Motorlu quattro Dört Çeker (530 HP Boost Modu & 630 Nm Tork)
        - Bang & Olufsen 3D Premium Ses Sistemi & Head-Up Display
        - Matrix LED Lazer Farlar & Karbon Tavan
        - Adaptif Havalı Süspansiyon & Spor E-Ses (e-tron Sport Sound)
      DESC
    },
    photos: [
      { filename: "01_front_three_quarter.jpg", path: "public/vehicles/audi/01_front_three_quarter.jpg" },
      { filename: "02_front.jpg",               path: "public/vehicles/audi/02_front.jpg" },
      { filename: "03_side.jpg",                path: "public/vehicles/audi/03_side.jpg" },
      { filename: "04_rear_three_quarter.jpg",  path: "public/vehicles/audi/04_rear_three_quarter.jpg" },
      { filename: "05_rear.jpg",                path: "public/vehicles/audi/05_rear.jpg" },
      { filename: "06_interior.jpg",            path: "public/vehicles/audi/06_interior.jpg" }
    ],
    defects: [
      {
        part_name: "Sol Arka Çamurluk",
        title: "Sol Arka Çamurluk - Vernik Geçişi",
        micron_value: 165,
        defect_type: "Lokal Boya",
        description: "165 Mikron Vernik Geçişi - Sürtme kaynaklı sol arka kordon altı yüzeysel boya işlemi, macunsuz mikron.",
        position_x: 72.0,
        position_y: 48.0,
        frame_index: 2,
        severity: "minor"
      },
      {
        part_name: "Sağ Marşpiyel",
        title: "Sağ Marşpiyel Yüzeysel Çizik",
        micron_value: 130,
        defect_type: "Kılcal Çizik",
        description: "130 Mikron - Plastik marşpiyel altı 2cm yüzeysel kılcal çizik, metal aksama sirayet etmemiştir.",
        position_x: 55.0,
        position_y: 78.0,
        frame_index: 1,
        severity: "minor"
      }
    ]
  },

  # 3. 2024 BMW i4 M50
  {
    attributes: {
      title: "2024 BMW i4 M50 Gran Coupe M Sport Pro",
      brand: "BMW",
      model_name: "i4 M50 Gran Coupe",
      year: 2024,
      price: 4_750_000,
      mileage: 9_200,
      fuel_type: "Elektrik",
      transmission: "Otomatik",
      color: "Mineral Gri (Mineral Grey Metallic)",
      body_type: "Sedan",
      expertise: "Hatasız / Boyasız / Değişensiz (Borusan Ekspertiz Onaylı)",
      tramer: "Tramer Kaydı Yok / 0 TL",
      dealer_name: "AutoAorta Maslak Atelier",
      dealer_phone: "+90 212 350 40 50",
      description: <<~DESC
        Borusan Otomotiv çıkışlı, 2024 Model BMW i4 M50 Gran Coupe M Sport Pro.
        - Çift Elektrik Motoru xDrive (544 HP & 795 Nm Tork, 0-100: 3.9 sn)
        - M Karbon Dış Paket & 20" Bicolor M Hafif Alaşım Jantlar
        - BMW Lazer Far & Harman Kardon Surround Ses Sistemi
        - BMW Kavisli Ekran (Curved Display) OS 8.5 & Sürüş Asistanı Professional
      DESC
    },
    photos: [
      { filename: "01_front_three_quarter.jpg", path: "public/vehicles/bmw/01_front_three_quarter.jpg" },
      { filename: "02_front.jpg",               path: "public/vehicles/bmw/02_front.jpg" },
      { filename: "03_side.jpg",                path: "public/vehicles/bmw/03_side.jpg" },
      { filename: "04_rear_three_quarter.jpg",  path: "public/vehicles/bmw/04_rear_three_quarter.jpg" },
      { filename: "05_rear.jpg",                path: "public/vehicles/bmw/05_rear.jpg" },
      { filename: "06_interior.jpg",            path: "public/vehicles/bmw/06_interior.jpg" }
    ],
    defects: [
      {
        part_name: "Ön Kaput",
        title: "Ön Kaput Şeffaf TPU Koruma Filmi",
        micron_value: 140,
        defect_type: "Orijinal",
        description: "140 Mikron (190µm TPU film dahil) - Tamamen hatasız ve çiziksiz orijinal fabrika boyası.",
        position_x: 50.0,
        position_y: 45.0,
        frame_index: 0,
        severity: "minor"
      }
    ]
  }
]

fleet_data.each_with_index do |item, idx|
  listing = Listing.new(item[:attributes])
  listing.status = :published

  item[:photos].each_with_index do |photo_info, p_idx|
    file_path = Rails.root.join(photo_info[:path])
    if File.exist?(file_path)
      listing.photos.attach(
        io: File.open(file_path),
        filename: photo_info[:filename],
        content_type: "image/jpeg"
      )
    end
  end

  listing.save!

  # Attach defects
  if item[:defects].present?
    item[:defects].each do |defect_attrs|
      listing.defects.create!(defect_attrs)
    end
  end

  # Create photo analyses for 360 spin ordering
  angles = %w[front_three_quarter front side rear_three_quarter rear interior]
  listing.photos.each_with_index do |photo, p_idx|
    PhotoAnalysis.create!(
      listing: listing,
      blob_id: photo.blob_id,
      detected_angle: angles[p_idx % angles.size],
      quality_score: 95 + (p_idx % 4),
      is_hero_candidate: p_idx == 0,
      spin_order: p_idx + 1,
      notes: "Doğrulanmış Stüdyo Çekimi"
    )
  end

  puts "✓ Oluşturuldu: #{listing.year} #{listing.brand} #{listing.model_name} (Kusurlar: #{listing.defects.count}, Fotoğraflar: #{listing.photos.count})"
end

puts "== Seed Tamamlandı: #{Listing.count} araç başarıyla eklendi =="
