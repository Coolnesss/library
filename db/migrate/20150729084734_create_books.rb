class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :name
      t.string :name_eng
      t.string :author
      t.text :description_sindhi
      t.text :description_eng
      t.integer :year

      t.timestamps null: false
    end
  end
end
