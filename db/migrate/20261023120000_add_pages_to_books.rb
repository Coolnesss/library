class AddPagesToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :pages, :integer
  end
end
