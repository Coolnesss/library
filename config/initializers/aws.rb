# aws-sdk-core 3.216+ sends CRC32 checksums on every request by default, and
# some S3-compatible services reject them. Only send them where S3 requires
# them. Aws.config applies to every client, so Paperclip's and Active Storage's.
Aws.config.update(
  request_checksum_calculation: "when_required",
  response_checksum_validation: "when_required"
)
