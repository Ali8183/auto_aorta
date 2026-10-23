class CreateListingsAndPhotoAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.string :title
      t.string :brand
      t.string :model_name
      t.integer :year
      t.decimal :price, precision: 12, scale: 2
      t.integer :mileage
      t.string :fuel_type
      t.string :transmission
      t.text :description
      t.integer :status, default: 0, null: false
      t.integer :hero_photo_id
      t.datetime :optimized_at
      t.datetime :auto_published_at

      t.timestamps
    end

    create_table :photo_analyses do |t|
      t.references :listing, null: false, foreign_key: true
      t.integer :blob_id, null: false
      t.string :detected_angle
      t.integer :quality_score
      t.boolean :is_hero_candidate, default: false, null: false
      t.integer :spin_order, default: 0, null: false
      t.string :notes

      t.timestamps
    end

    add_index :photo_analyses, :blob_id
    add_index :photo_analyses, [:listing_id, :spin_order]
  end
end
