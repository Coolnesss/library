class AddAuthorSindhiToBook < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :author_sindhi, :string
  end
end
