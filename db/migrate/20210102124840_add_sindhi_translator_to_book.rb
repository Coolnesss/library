class AddSindhiTranslatorToBook < ActiveRecord::Migration[5.2]
  def change
    add_column :books, :translator_sindhi, :string
  end
end
