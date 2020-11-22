class AddLanguageToBook < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :language, :string
  end
end
