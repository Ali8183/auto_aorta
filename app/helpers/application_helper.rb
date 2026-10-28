module ApplicationHelper
  BRAND_CDN_FALLBACKS = {
    "Porsche"       => "https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?auto=format&fit=crop&w=1200&q=80",
    "BMW"           => "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=1200&q=80",
    "Tesla"         => "https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=1200&q=80",
    "Audi"          => "https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?auto=format&fit=crop&w=1200&q=80",
    "Mercedes-Benz" => "https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=1200&q=80"
  }.freeze

  BRAND_ANGLE_GALLERIES = {
    "Porsche" => {
      "front_three_quarter" => "https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?auto=format&fit=crop&w=1200&q=80",
      "front"               => "https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80",
      "side"                => "https://images.unsplash.com/photo-1580274455191-1c62238fa333?auto=format&fit=crop&w=1200&q=80",
      "rear_three_quarter"  => "https://images.unsplash.com/photo-1611821064430-0d40291d0f0b?auto=format&fit=crop&w=1200&q=80",
      "rear"                => "https://images.unsplash.com/photo-1544636331-e26879cd4d9b?auto=format&fit=crop&w=1200&q=80",
      "interior"            => "https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=1200&q=80"
    },
    "Tesla" => {
      "front_three_quarter" => "https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=1200&q=80",
      "front"               => "https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&w=1200&q=80",
      "side"                => "https://images.unsplash.com/photo-1536700503339-1e4b06520771?auto=format&fit=crop&w=1200&q=80",
      "rear_three_quarter"  => "https://images.unsplash.com/photo-1619767886558-efdc259cde1a?auto=format&fit=crop&w=1200&q=80",
      "rear"                => "https://images.unsplash.com/photo-1571987502227-9231b837d92a?auto=format&fit=crop&w=1200&q=80",
      "interior"            => "https://images.unsplash.com/photo-1620891549027-942fdc95d3f5?auto=format&fit=crop&w=1200&q=80"
    },
    "BMW" => {
      "front_three_quarter" => "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=1200&q=80",
      "front"               => "https://images.unsplash.com/photo-1617531653332-bd46c24f2068?auto=format&fit=crop&w=1200&q=80",
      "side"                => "https://images.unsplash.com/photo-1580273916550-e323be2ae537?auto=format&fit=crop&w=1200&q=80",
      "rear_three_quarter"  => "https://images.unsplash.com/photo-1556189250-72ba954cfc2b?auto=format&fit=crop&w=1200&q=80",
      "rear"                => "https://images.unsplash.com/photo-1607853202273-797f1c22a38e?auto=format&fit=crop&w=1200&q=80",
      "interior"            => "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=1200&q=80"
    }
  }.freeze

  DEFAULT_CDN_FALLBACK = "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1200&q=80".freeze

  def brand_angle_gallery(listing_or_brand = nil)
    brand = listing_or_brand.respond_to?(:brand) ? listing_or_brand.brand : listing_or_brand.to_s
    (BRAND_ANGLE_GALLERIES[brand] || BRAND_ANGLE_GALLERIES["BMW"]).with_indifferent_access
  end

  def vehicle_fallback_image(listing_or_brand = nil)
    brand = if listing_or_brand.respond_to?(:brand)
      listing_or_brand.brand
    else
      listing_or_brand.to_s
    end
    BRAND_CDN_FALLBACKS[brand] || DEFAULT_CDN_FALLBACK
  end

  def vehicle_angle_fallback_image(listing_or_brand = nil, angle: nil, index: 0)
    brand = listing_or_brand.respond_to?(:brand) ? listing_or_brand.brand : listing_or_brand.to_s
    gallery = BRAND_ANGLE_GALLERIES[brand]
    return vehicle_fallback_image(brand) unless gallery

    if angle.present? && gallery[angle.to_s]
      gallery[angle.to_s]
    else
      values = gallery.values
      values[index.to_i % values.size]
    end
  end

  def valid_active_storage_photo?(photo)
    return false unless photo.present? && photo.respond_to?(:blob) && photo.blob.present?
    # Reject 1x1 FALLBACK_JPEG (158 bytes) or tiny dummy test strings (< 2 KB)
    return false if photo.blob.byte_size.to_i <= 2048

    ActiveStorage::Blob.service.exist?(photo.blob.key)
  rescue StandardError
    false
  end

  def safe_photo_url(photo, listing = nil, angle: nil, index: 0)
    if valid_active_storage_photo?(photo)
      begin
        url_for(photo)
      rescue StandardError
        vehicle_angle_fallback_image(listing, angle: angle, index: index)
      end
    else
      detected_angle = angle
      if detected_angle.blank? && photo.present? && listing.respond_to?(:photo_analyses)
        analysis = listing.photo_analyses.find { |a| a.blob_id == photo.blob_id }
        detected_angle = analysis&.detected_angle
      end
      vehicle_angle_fallback_image(listing, angle: detected_angle, index: index)
    end
  end

  def listing_hero_image_url(listing)
    safe_photo_url(listing&.hero_photo, listing, angle: "front_three_quarter", index: 0)
  end

  def safe_spin_image_urls(listing, spin_photos)
    if spin_photos.present? && spin_photos.any?
      spin_photos.map.with_index do |photo, idx|
        safe_photo_url(photo, listing, index: idx)
      end
    else
      angles = %w[front_three_quarter front side rear_three_quarter rear]
      angles.map.with_index { |ang, idx| vehicle_angle_fallback_image(listing, angle: ang, index: idx) }
    end
  end
end


