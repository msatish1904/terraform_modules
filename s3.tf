resource "aws_s3_bucket" "s3" { 
  bucket        = var.bucket_name
  tags          = var.tags 
}

resource "aws_s3_bucket_versioning" "s3" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.s3.id

  versioning_configuration {
    status = "Enabled" 
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "buckets" {
  bucket = aws_s3_bucket.s3.id
  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
    id     = "Abort incomplete Multipart Uploads after 7 days"
    status = "Enabled"
  }

  rule {
    id = "expire objects"
    noncurrent_version_expiration {
      noncurrent_days = 45
    }
    expiration {
      expired_object_delete_marker = true
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "logging" {
  count          = var.enable_logging ? 1 : 0
  bucket         = aws_s3_bucket.s3.id
  target_bucket  = var.enable_logging ? var.logging_target_bucket : null
  target_prefix  = var.enable_logging ? var.logging_target_prefix : null 
}

resource "aws_s3_bucket_public_access_block" "bucket_public_policy" {
  bucket                  = aws_s3_bucket.s3.id
  block_public_acls       = var.block_public_acls 
  block_public_policy     = var.block_public_policy 
  ignore_public_acls      = var.ignore_public_acls 
  restrict_public_buckets = var.restrict_public_buckets 
}



resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption_config" {
  bucket = aws_s3_bucket.s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count      = var.enable_replication ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.s3]  // Makes sure that replication doesn't start until versioning is enabled on the source bucket

  role   = var.enable_replication ? aws_iam_role.replication[0].arn : null
  bucket = aws_s3_bucket.s3.id

  rule {
    status = "Enabled"

    destination {
      bucket        = var.destination_bucket
      storage_class = "STANDARD"
    }
  }
}

resource "aws_sns_topic" "sns_topic" { 
  count                       = var.create_sns_topic ? 1 : 0
  name                        = var.sns_topic_name
  kms_master_key_id           = var.kms_key_arn
  tags                        = var.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.enable_bucket_notification  ? 1 : 0
  bucket = aws_s3_bucket.s3.id

  dynamic "topic" {
    for_each = var.enable_bucket_notification && var.create_sns_topic ? [1] : []

    content {
      topic_arn = aws_sns_topic.sns_topic[0].arn
      events    = ["s3:ObjectCreated:*"]
      filter_prefix = ".log"
    }
  }
}

resource "aws_sns_topic_policy" "policy" {
  count = var.create_sns_topic ? 1 : 0

  arn    = aws_sns_topic.sns_topic[0].arn
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Sid       = "AllowS3ToPublish",
      Effect    = "Allow",
      Principal = "*",
      Action    = "sns:Publish",
      Resource  = aws_sns_topic.sns_topic[0].arn,
      Condition = {
        ArnLike = {
          "aws:SourceArn" = aws_s3_bucket.s3.arn
        }
      }
    }]
  })
}

