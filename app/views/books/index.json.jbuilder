json.array!(@books) do |book|
  json.extract! book, :id, :name, :name_eng, :author, :description_sindhi, :description_eng, :year
  json.url book_url(book, format: :json)
  json.categories book.categories.map(&:name)
end
