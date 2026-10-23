# AGENT.md - AutoAorta AI Geliştirme ve Mimari Kılavuzu

Bu doküman, **AutoAorta AI (Fortune 500 Automotive Merchandising & 360 Spin Studio)** projesinin Google DeepMind / Antigravity IDE ortamında **Gemini 3.8 Flash (High)** agentic modeli ile nasıl geliştirildiğini, karşılaşılan mimari zorlukları, alınan kararları ve çalıştırma standartlarını belgeler.

---

## 1. Agent Çalışma Ortamı & Model Bilgileri
* **Geliştirme Ortamı:** Google Antigravity IDE (Agentic Coding Pair Programmer)
* **Yapay Zeka Modeli:** Gemini 3.8 Flash (High Reasoning Effort)
* **İşletim Sistemi:** Windows (PowerShell CLI)
* **Çekirdek Teknoloji Yığını:** Ruby on Rails 8.1.4, Ruby 3.3.0, Propshaft, Importmap, Stimulus JS, Tailwind CSS v4, SQLite3, Active Storage.

---

## 2. Otonom Geliştirme Döngüsü ve Kritik Mimari Kararlar

Geliştirme sürecinde agent otonom olarak terminal komutları, veritabanı migration'ları ve dosya manipülasyonlarını yönetmiş; karşılaşılan kritik sistem engellerini şu şekilde aşmıştır:

### A. ActiveRecord `model_name` Çatışması ve Dinamik `CarModelString`
* **Problem:** Şartnamede araç için `model_name` sütunu istendi. Ancak ActiveRecord içinde `model_name` ayrılmış bir sınıfsal/örneksel delegasyon metodudur (`ActiveModel::Naming.model_name`). Rails doğrudan `ActiveRecord::DangerousAttributeError` fırlatır ve form üretimi (`form_with`) çöker.
* **Agent Çözümü:** `Listing` modeli içerisinde `dangerous_attribute_method?` filtrelendi ve `CarModelString < String` proxy sınıfı geliştirildi. Bu sayede `listing.model_name` hem veritabanındaki model adını (örn: "320i Sedan") döndüren bir String gibi davranmakta, hem de form yardımcıları (`form_with`) için `param_key`, `route_key` gibi ActiveModel çağrılarını sınıfa delege etmektedir.

### B. Tailwind CSS Derleme ve Windows / Bun EEXIST Çözümü
* **Problem:** Windows dosya sistemi ve OneDrive üzerinde `tailwindcss:build` çalıştırılırken gömülü Bun derleyicisi `EEXIST: file already exists, mkdir app/assets/builds` hatası verdi.
* **Agent Çözümü:** Otonom olarak `npm install -D tailwindcss @tailwindcss/cli` kuruldu ve `lib/tasks/tailwindcss.rake` ile `tailwindcss:build` Rake görevi doğrudan Node tabanlı CLI'a yönlendirilerek derleme 88ms'ye indirildi.

### C. ActiveSupport Testing `travel_to` Kuralı
* **Problem:** Rails 8.1'de iç içe `travel_to` blokları çağırmak zaman çakışması uyarısı vermektedir.
* **Agent Çözümü:** Testler `travel_to(initial_time)` ile referans zamana çekilip `travel(24.hours + 1.minute)` ile doğrusal olarak ilerletilmiş, `teardown { travel_back }` ile test izolasyonu kusursuz sağlanmıştır.

---

## 3. Testlerin Çalıştırılması ve Doğrulama

Tüm model ve entegrasyon testleri Rails'in yerleşik test koşucusu ile çalıştırılır:

```bash
# Tüm testleri çalıştırmak için:
bin/rails test

# Sadece model SLA kuralı testini çalıştırmak için:
bin/rails test test/models/listing_test.rb

# Controller entegrasyon testlerini çalıştırmak için:
bin/rails test test/controllers/listings_controller_test.rb
```

### Test Kapsamı:
* `ListingTest`:
  * `initial status is draft`
  * `manual publish! transitions status to published`
  * `start_ai_optimization! runs vision analysis, sets optimized status and optimized_at`
  * `24-hour SLA time rule: does not auto-publish when under 24 hours`
  * `24-hour SLA time rule: automatically publishes when 24 hours have elapsed using travel_to`
  * `auto_publish_if_expired! does nothing if listing is not optimized`
* `ListingsControllerTest`:
  * `index`, `show`, `new`, `create`, `optimize`, `publish`, `simulate_time_lapse` eylemleri.

**Sonuç:** `13 runs, 48 assertions, 0 failures, 0 errors, 0 skips` (Tamamı Yeşil).

---

## 4. Tohum Verisi (Seeds) ve Canlı Çalıştırma

Projede gerçek dünya senaryosunu test etmek için Wikimedia Commons üzerinden telifsiz, orijinal BMW 3 Serisi fotoğrafları çekilir:

```bash
# Veritabanını sıfırlayıp BMW 3 Serisi ve 6 açılı fotoğrafları bağlamak için:
bin/rails db:seed

# Web sunucusunu başlatmak için:
bin/rails server
```
Tarayıcıdan `http://localhost:3000` adresine gidildiğinde interaktif sanal tur ve SLA test butonu canlıda görüntülenebilir.
