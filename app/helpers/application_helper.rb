module ApplicationHelper
  BRAND_CDN_FALLBACKS = {
    "Porsche"       => "https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?auto=format&fit=crop&w=1200&q=80",
    "BMW"           => "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=1200&q=80",
    "Tesla"         => "https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=1200&q=80",
    "Audi"          => "https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?auto=format&fit=crop&w=1200&q=80",
    "Mercedes-Benz" => "https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=1200&q=80"
  }.freeze

  DEFAULT_CDN_FALLBACK = "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1200&q=80".freeze

  def vehicle_fallback_image(listing_or_brand = nil)
    brand = if listing_or_brand.respond_to?(:brand)
      listing_or_brand.brand
    else
      listing_or_brand.to_s
    end
    BRAND_CDN_FALLBACKS[brand] || DEFAULT_CDN_FALLBACK
  end

  def listing_hero_image_url(listing)
    if listing&.hero_photo.present?
      begin
        url_for(listing.hero_photo)
      rescue StandardError
        vehicle_fallback_image(listing)
      end
    else
      vehicle_fallback_image(listing)
    end
  end
end

