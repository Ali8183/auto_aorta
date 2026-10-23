class Listing < ApplicationRecord
  # Handle ActiveRecord's reserved 'model_name' instance method gracefully
  class CarModelString < String
    attr_accessor :listing_class

    def method_missing(m, *args, &block)
      if listing_class && listing_class.model_name.respond_to?(m)
        listing_class.model_name.send(m, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(m, include_private = false)
      (listing_class && listing_class.model_name.respond_to?(m, include_private)) || super
    end
  end

  def self.dangerous_attribute_method?(name)
    return false if name.to_s == "model_name"
    super
  end

  def model_name
    val = read_attribute(:model_name)
    str = CarModelString.new(val.to_s)
    str.listing_class = self.class
    str
  end

  def model_name=(val)
    write_attribute(:model_name, val.to_s)
  end

  enum :status, { draft: 0, analyzing: 1, optimized: 2, published: 3 }, default: :draft

  has_many_attached :photos
  has_many :photo_analyses, dependent: :destroy

  validates :title, :brand, :model_name, :year, :price, presence: true
  validates :year, numericality: { greater_than: 1900, less_than_or_equal_to: ->(_) { Time.current.year + 1 } }
  validates :price, numericality: { greater_than: 0 }

  def start_ai_optimization!
    analyzing!
    VehicleVisionService.new(self).call
    update!(status: :optimized, optimized_at: Time.current)
  end

  def publish!
    published!
  end

  def auto_publish_if_expired!
    if optimized? && optimized_at.present? && optimized_at <= 24.hours.ago
      update!(status: :published, auto_published_at: Time.current)
      true
    else
      false
    end
  end

  def hero_photo
    return photos.first unless hero_photo_id.present?
    photos.find_by(id: hero_photo_id) || photos.find_by(blob_id: hero_photo_id) || photos.first
  end

  def hero_photo_analysis
    photo_analyses.find_by(is_hero_candidate: true) || photo_analyses.order(quality_score: :desc).first
  end

  def spin_photos
    spin_analyses = photo_analyses.where("spin_order > 0").order(:spin_order)
    return photos.to_a if spin_analyses.empty?

    blob_map = photos.index_by(&:blob_id)
    ordered = spin_analyses.map { |a| blob_map[a.blob_id] }.compact
    ordered.presence || photos.to_a
  end
end
