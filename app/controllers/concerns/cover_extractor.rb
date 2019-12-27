require 'grim'
require 'paperclip/media_type_spoof_detector'

module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end

module CoverExtractor
    def self.extract(book)
      
      return if not book.attachment.present?

      pdf_file = Tempfile.new("temp.pdf")
      book.attachment.copy_to_local_file :original, pdf_file.path
      pdf = Grim.reap(pdf_file.path)
      png_file = File.new(Rails.root.join('tmp/cover.png').to_s, 'w')
      pdf[0].save(png_file.path, {
        :width => 1024,
        :quality => 90,
      })
      book.cover = png_file
      book.save!
    end
end
  