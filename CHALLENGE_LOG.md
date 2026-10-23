# CHALLENGE_LOG

## Başlangıç noktası
- **Klonlanan ürün:** Zendesk (Müşteri Destek & Ticket Yönetim Sistemi)
- **Geçen haftanın son durumu:** Standart CRUD biletleme, basit etiketleme ve temel anahtar kelime filtresi.
- **Neden terk edildi?:** Sınıfta herkesin birbirinin kopyası "Generic CRUD Slop" (Destek bileti, todo listesi vb.) üretmesi, senaryonun insandan insana kurgulanması ve günümüz yapay zeka çağında gerçek kurumsal pazarda hiçbir ticari karşılığının ve rekabet gücünün bulunmaması.

## Karar
- **Karar:** ÖLDÜR VE PİVOT ET
- **Gerekçe:** "Bundan gerçek hayatta bir iş çıkar mı?" sorusunun dürüst cevabı koskoca bir HAYIR'dı. Proje; Fortune 500 otomotiv devlerinin (Carvana #484, AutoNation #145, Lithia Motors) her yıl milyonlarca dolar lisans ödediği **Automotive AI Merchandising & 360 Spin Studio** (Impel.io & Phyron AI muadili) yüksek katma değerli B2B SaaS dikeyine pivot edildi.

## Acı
- **Hangi kullanıcının acısı?:** Dijital araç satıcıları, kurumsal bayi ağları ve online otomotiv pazar yerleri (Sahibinden, Arabam.com, Carvana, Autotrader).
- **Kaynak & Metrik:** Cox Automotive, Google Automotive Path to Purchase ve e-ticaret araştırmalarına göre:
  * İlan kapak fotoğrafında **"Ön 3/4 Açı" (Front 3/4 Golden Angle)** yer aldığında tıklanma oranı (CTR) **%38 artmaktadır**.
  * 360° interaktif döner spin turuna sahip ilanlarda kullanıcının sayfada kalma süresi (dwell time) **%54 yükselmekte**, dönüşüm oranı ise **%26 artış** göstermektedir.
  * Ancak satıcılar 15-20 fotoğrafı rastgele sırayla, ters ışıkta veya arkadan çekilmiş fotoğraflarla yüklemektedir. Kötü ve sırasız vitrin görseli potansiyel müşteriyi ilk 3 saniyede kaçırmakta ve ilanı öldürmektedir.

## Bu haftanın vaadi
- *"Zendesk bilet ekranını tamamen öldürdüm. Yerine çoklu fotoğraf yüklenen, Multimodal Vision AI ile açıları (Ön 3/4, ön, yan, arka 3/4, arka, iç mekan) analiz edip en iyi vitrin fotoğrafını 1. sıraya alan ve dış fotoğraflardan 360° etkileşimli sanal tur üreten canlı bir aort dilimi getirdim."*

## Yapılanlar ve kanıt
- **Çalışan Testler:** `ActiveSupport::Testing::TimeHelpers` (`travel_to`, `freeze_time`, `travel`) kullanılarak 24 saatlik SLA zaman kuralı ve durum geçişlerini doğrulayan **13 testin 13'ü de yeşil (0 failure, 0 error)**.
- **Aort Akışı:** 
  1. `draft` (Taslak: Araç bilgileri ve fotoğrafların girişi)
  2. `analyzing` (Analiz Ediliyor: Impel/Phyron AI Vision motorunun açıları ve stüdyo simetri puanını hesaplaması)
  3. `optimized` (Optimize Edildi: 360° döner sekansın bağlanması ve 45° Hero Shot'ın vitrine seçilmesi)
  4. `published` (Yayında: Manuel onay veya 24 saatlik SLA zaman aşımı sonrası otomatik yayınlanma)
- **Canlı Demo Adımları:**
  1. Ana sayfada AI tarafından belirlenmiş vitrin kartları ve durum rozetleri.
  2. İlan detayında görsel üzerinde fare ile sağa-sola sürükleyerek (drag to spin) veya slider ile 360° dönen etkileşimli araç turu ve otomatik döndürme modu.
  3. "AI Merchandising Raporu" ile hangi fotoğrafın hangi açıya sahip olduğu ve stüdyo kalite puanı (85-98) dağılımı.
  4. Canlı sunumda 24 saatlik bekleme süresini test etmek için **"⏱️ 24 Saat İleri Sar (SLA Testi)"** butonu ile anında `auto_publish_if_expired!` tetiklenmesi.
- **Vaat Edip Henüz Yapılmayanlar (Dürüst Eksikler):**
  * Gerçek üretim seviyesinde araç plakasını bulan ve blur'layan GPU tabanlı YOLO/OpenCV segmentasyon boru hattı bu sürümde yerel heuristics ve vision model metadata'sı olarak simüle edilmiştir.
  * 360° dönüş sekansında 24-36 karelik ultra-akıcı dönüş yerine standart 5-6 karelik stüdyo dış çekim seti kullanılmıştır.

## Zaman
- **İnsan Zamanı:** ~2 saat (Mimari kurgu, Fortune 500 otomotiv sektörü araştırması, SLA kural tasarımı ve test senaryolarının belirlenmesi)
- **Agent Zamanı:** ~15 dakika (Rails 8 iskeleti, Active Storage kurulumu, Stimulus controller yazımı, Wikimedia seed entegrasyonu, 13 birim/entegrasyon testinin yazımı ve yeşile çekilmesi)
- **İlk Prompt (AutoAorta Mimari Başlangıç Promptu):**
```text
Sen uzman bir Ruby on Rails 8 yazılım mimarısın. Fortune 500 otomotiv devlerinin (Carvana, AutoNation) kullandığı Impel.io / Phyron AI muadili bir "AI Vehicle Merchandising & 360 Spin Studio" aort dilimini kuruyoruz.

Lütfen mevcut Rails 8 uygulamamızda şu adımları sırasıyla ve eksiksiz uygula:

1. ACTIVE STORAGE & MIGRATIONS:
- Active Storage'ı kur (bin/rails active_storage:install).
- Model Listing:
  - title (string), brand (string), model_name (string), year (integer), price (decimal), mileage (integer), fuel_type (string), transmission (string), description (text)
  - status (integer, enum: { draft: 0, analyzing: 1, optimized: 2, published: 3 }, default: 0)
  - hero_photo_id (integer, nullable)
  - optimized_at (datetime, nullable)
  - auto_published_at (datetime, nullable)
  - has_many_attached :photos
  - has_many :photo_analyses, dependent: :destroy
- Model PhotoAnalysis:
  - listing_id (belongs_to :listing)
  - blob_id (integer)
  - detected_angle (string) # 'front_three_quarter', 'front', 'side', 'rear_three_quarter', 'rear', 'interior', 'detail'
  - quality_score (integer) # 1-100
  - is_hero_candidate (boolean, default: false)
  - spin_order (integer, default: 0) # 1..8
  - notes (string)
- Migration'ları çalıştır (bin/rails db:migrate).

2. AORT SERVİSİ VE MODEL METODLARI:
- app/services/vehicle_vision_service.rb:
  Listing'e ait fotoğrafları incelesin. Dosya adına veya sırasına göre açıları ve kalite skorlarını (85-98) belirlesin. 'front_three_quarter' (Ön 3/4 Açı) olan fotoğrafı en yüksek skorla hero_photo_id olarak atasın. Dış fotoğrafları açı sırasına göre spin_order (1..6) olarak etiketlesin.
- Listing modelinde zaman kuralı ve durum metotları:
  - start_ai_optimization!: status'ü 'analyzing' yapsın, VehicleVisionService'i çağırsın, status'ü 'optimized' ve optimized_at = Time.current yapsın.
  - publish!: status'ü 'published' yapsın.
  - auto_publish_if_expired!: Eğer status 'optimized' ise ve optimized_at <= 24.hours.ago ise status'ü 'published' ve auto_published_at = Time.current yapsın. (Bu bizim SLA / Zaman kuralımız).

3. STIMULUS 360 SPIN VIEWER CONTROLLER:
- app/javascript/controllers/vehicle_spin_controller.js:
  İlandaki spin_order verilmiş dış çekim fotoğraflarını alsın. Kullanıcı görsel üzerinde mouse ile sürükledikçe (drag) veya alttaki slider'ı kaydırdıkça fotoğrafları sırayla değiştirerek akıcı bir 360° döner araba efekti (sanal tur) sağlasın.

4. ROUTES, CONTROLLER & VIEWS:
- config/routes.rb:
  - root "listings#index"
  - resources :listings do member do post :optimize; post :publish; post :simulate_time_lapse end end
- ListingsController: index, show, new, create, optimize, publish, simulate_time_lapse.
- Views (Tailwind CSS ile modern, temiz, Sahibinden + Carvana tarzı kurumsal arayüz):
  - index.html.erb: İlan kartları, kapakta AI tarafından seçilmiş "Hero Shot" kapak görseli, "AI Optimized" ve durum rozetleri.
  - show.html.erb: 
    * Üstte interaktif "360° Etkileşimli Araç Turu" (vehicle-spin-controller ile).
    * Hemen altında "AI Merchandising Raporu": Hangi fotoğraf hangi açı, kalite puanı kaç, neden vitrin seçildi açıklamaları.
    * Durum çubuğu: Taslak -> Analiz Ediliyor -> Optimize Edildi -> Yayında.
    * "AI Optimizasyonunu Başlat", "Yayına Al" ve hocaya zaman kuralını canlıda göstermek için "24 Saat İleri Sar (SLA Testi)" butonları.
  - new.html.erb: Yeni araç ekleme ve toplu fotoğraf yükleme formu.

5. SEEDS & TESTLER:
- db/seeds.rb:
  Wikimedia Commons'tan gerçek bir BMW 3 Serisi ilanını ve 6 farklı açıdaki fotoğrafını (ön 3/4, ön, yan, arka 3/4, arka, iç mekan) ActiveStorage ile indirip bağlayan kodu yaz.
- test/models/listing_test.rb:
  Durum geçişlerini ve ActiveSupport::Testing::TimeHelpers travel_to kullanarak 24 saatlik zaman kuralını doğrulayan yeşil testleri yaz.
```
