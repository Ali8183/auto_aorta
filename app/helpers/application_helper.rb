module ApplicationHelper
  BRAND_CDN_FALLBACKS = {
    "BMW"           => "/vehicles/bmw/01_front_three_quarter.jpg",
    "Tesla"         => "/vehicles/tesla/01_front_three_quarter.jpg",
    "Porsche"       => "/vehicles/porsche/01_front_three_quarter.jpg",
    "Audi"          => "/vehicles/bmw/01_front_three_quarter.jpg",
    "Mercedes-Benz" => "/vehicles/bmw/01_front_three_quarter.jpg"
  }.freeze

  BRAND_ANGLE_GALLERIES = {
    "BMW" => {
      "front_three_quarter" => "/vehicles/bmw/01_front_three_quarter.jpg",
      "front"               => "/vehicles/bmw/02_front.jpg",
      "side"                => "/vehicles/bmw/03_side.jpg",
      "rear_three_quarter"  => "/vehicles/bmw/04_rear_three_quarter.jpg",
      "rear"                => "/vehicles/bmw/05_rear.jpg",
      "interior"            => "/vehicles/bmw/06_interior.jpg"
    },
    "Tesla" => {
      "front_three_quarter" => "/vehicles/tesla/01_front_three_quarter.jpg",
      "front"               => "/vehicles/tesla/02_front.jpg",
      "side"                => "/vehicles/tesla/03_side.jpg",
      "rear_three_quarter"  => "/vehicles/tesla/04_rear_three_quarter.jpg",
      "rear"                => "/vehicles/tesla/05_rear.jpg",
      "interior"            => "/vehicles/tesla/06_interior.jpg"
    },
    "Porsche" => {
      "front_three_quarter" => "/vehicles/porsche/01_front_three_quarter.jpg",
      "front"               => "/vehicles/porsche/02_front.jpg",
      "side"                => "/vehicles/porsche/03_side.jpg",
      "rear_three_quarter"  => "/vehicles/porsche/04_rear_three_quarter.jpg",
      "rear"                => "/vehicles/porsche/05_rear.jpg",
      "interior"            => "/vehicles/porsche/06_interior.jpg"
    }
  }.freeze

  DEFAULT_CDN_FALLBACK = "/vehicles/bmw/01_front_three_quarter.jpg".freeze

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
    gallery = BRAND_ANGLE_GALLERIES[brand] || BRAND_ANGLE_GALLERIES["BMW"]

    if angle.present? && gallery[angle.to_s]
      gallery[angle.to_s]
    else
      values = gallery.values
      values[index.to_i % values.size]
    end
  end

  def valid_active_storage_photo?(photo)
    return false unless photo.present? && photo.respond_to?(:blob) && photo.blob.present?
    return false if photo.blob.byte_size.to_i <= 2048

    # For seeded fleet photos (01_... to 06_...), always use the verified single-vehicle gallery
    # so no legacy mismatched blobs from older database seeds can ever surface.
    filename = photo.blob.filename.to_s
    return false if filename.match?(/\A0[1-6]_/)

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

  def vehicle_3d_config(listing)
    brand = listing&.brand.to_s
    case brand
    when "Tesla"
      {
        color_label: "Pearl White Multi-Coat (PPSW) - PlayCanvas WebGL 3D",
        color_tr: "İnci Beyazı (Pearl White Multi-Coat)",
        paint_code: "PPSW • Multi-Coat White",
        hex: "#F1F5F9",
        rgb: [ 0.94, 0.96, 0.98 ],
        body_style: "fastback",
        package_name: "Long Range Dual Motor AWD"
      }
    when "Porsche"
      {
        color_label: "Volcano Grey Metallic (2H) - PlayCanvas WebGL 3D",
        color_tr: "Koyu Gri (Volcano Grey Metallic)",
        paint_code: "2H • Volcano Grey Metallic",
        hex: "#3B4046",
        rgb: [ 0.23, 0.25, 0.28 ],
        body_style: "suv",
        package_name: "Macan GTS Sport Package"
      }
    else
      {
        color_label: "Protonic Blue / Frozen Grey (W97) - PlayCanvas WebGL 3D",
        color_tr: "Protonic Blue / Frozen Grey",
        paint_code: "W97 • Protonic Blue Metallic",
        hex: "#0284C7",
        rgb: [ 0.01, 0.52, 0.78 ],
        body_style: "coupe",
        package_name: "i8 Coupe Plug-in Hybrid (369 HP)"
      }
    end
  end
end
