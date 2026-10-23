class AddCommercialSpecsToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :color, :string, default: "Metalik Gri"
    add_column :listings, :body_type, :string, default: "Sedan"
    add_column :listings, :tramer, :string, default: "Hasar Kaydı Yok / 0 TL"
    add_column :listings, :expertise, :string, default: "Hatasız / Boyasız / Değişensiz"
    add_column :listings, :dealer_phone, :string, default: "+90 532 500 40 30"
    add_column :listings, :dealer_name, :string, default: "AutoAorta Premier Fleet"
  end
end
