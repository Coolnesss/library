class AddAuthorSindhiToBook < ActiveRecord::Migration
  def change
    add_column :books, :author_sindhi, :string
  end
end
