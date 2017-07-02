class AddPublisherToBook < ActiveRecord::Migration
  def change
    add_column :books, :publisher, :string
  end
end
