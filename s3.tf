resource "aws_s3_bucket" "s3" {
  for_each  = var.s3_config
  bucket    = each.key
  tags      = merge({ "Name" = each.key }, var.tags)
}

resource "aws_s3_bucket_public_access_block" "bucket_public_policy" {
  for_each  = var.s3_config
  bucket = aws_s3_bucket.s3[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each  = var.s3_config
  bucket = aws_s3_bucket.s3[each.key].id
  versioning_configuration {
    status = each.value.bucket_versioning_configuration_status
  }
}

#resource "aws_s3_bucket_policy" "policy" {
#  for_each  = var.s3_config
#  bucket = aws_s3_bucket.s3[each.key].id
#  policy = each.value.bucket_policy
#}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption_config" {
  for_each  = var.s3_config
  bucket = aws_s3_bucket.s3[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
