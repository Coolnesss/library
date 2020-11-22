class AddTranslatorToBooks < ActiveRecord::Migration[5.2]
  def change
    add_column :books, :translator, :string
  end
end
