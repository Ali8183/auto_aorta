class CreateDefects < ActiveRecord::Migration[8.1]
  def change
    create_table :defects do |t|
      t.references :listing, null: false, foreign_key: true
      t.string :title
      t.string :part_name
      t.text :description
      t.integer :micron_value
      t.string :defect_type
      t.float :position_x
      t.float :position_y
      t.integer :frame_index
      t.string :severity

      t.timestamps
    end
  end
end
