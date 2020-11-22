class AddIsbnToBook < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :isbn, :string
  end
end
