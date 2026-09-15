class AddIndexesToBookCategories < ActiveRecord::Migration[6.1]
  def change
    add_index :book_categories, :book_id
    add_index :book_categories, :category_id
    # Ransack joins through this table and applies DISTINCT on every /books
    # request; the pair also backs the uniqueness validation in BookCategory.
    add_index :book_categories, [:book_id, :category_id], unique: true
  end
end
