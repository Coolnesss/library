class AddPublisherToBook < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :publisher, :string
  end
end
