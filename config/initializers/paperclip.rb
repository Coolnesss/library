require 'paperclip/media_type_spoof_detector'

# The books are scans whose file name, extension and detected media type often
# disagree, and Paperclip rejects such uploads as spoofed. Turning the check
# off is deliberate: uploads are limited to signed-in, admin-approved users.
#
# This belongs in an initializer, not in CoverExtractor where it used to live.
# There it only took effect once that class happened to be autoloaded, so in
# development the first upload of a boot could still be rejected.
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
