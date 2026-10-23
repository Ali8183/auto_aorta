class PhotoAnalysis < ApplicationRecord
  belongs_to :listing
  belongs_to :blob, class_name: "ActiveStorage::Blob", foreign_key: :blob_id, optional: true

  validates :blob_id, presence: true
  validates :quality_score, numericality: { in: 1..100 }, allow_nil: true
  validates :spin_order, numericality: { in: 0..8 }

  ANGLE_NAMES = {
    "front_three_quarter" => "Ön 3/4 Vitrin Açısı",
    "front"               => "Ön Cephe (Tam)",
    "side"                => "Yan Profil",
    "rear_three_quarter"  => "Arka 3/4 Açılı",
    "rear"                => "Arka Cephe",
    "interior"            => "İç Mekan / Kokpit",
    "detail"              => "Detay / Jant Odaklı"
  }.freeze

  def angle_label
    ANGLE_NAMES[detected_angle] || detected_angle.to_s.titleize
  end

  def attachment
    listing.photos.find { |p| p.blob_id == blob_id } || listing.photos.find_by(blob_id: blob_id)
  end
end
