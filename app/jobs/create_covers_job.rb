class CreateCoversJob < ApplicationJob
  queue_as :default

  def perform(*books)
    books.each do |book|
      CoverExtractor.extract book
    end
  end
end
