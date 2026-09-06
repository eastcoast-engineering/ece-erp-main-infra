resource "aws_s3_bucket" "files" {
  bucket        = coalesce(var.storage_bucket_name, "${local.name_prefix}-backend-files-${data.aws_caller_identity.current.account_id}")
  force_destroy = false

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-backend-files"
    Component = "BackendStorage"
  })
}

resource "aws_s3_bucket_ownership_controls" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = var.storage_cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 300
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket" "chat" {
  bucket        = coalesce(var.chat_storage_bucket_name, "${local.name_prefix}-chat-${data.aws_caller_identity.current.account_id}")
  force_destroy = false

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-chat"
    Component = "ChatStorage"
  })
}

resource "aws_s3_bucket_ownership_controls" "chat" {
  bucket = aws_s3_bucket.chat.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "chat" {
  bucket = aws_s3_bucket.chat.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "chat" {
  bucket = aws_s3_bucket.chat.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "chat" {
  bucket = aws_s3_bucket.chat.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "chat" {
  bucket = aws_s3_bucket.chat.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = var.storage_cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 300
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "chat" {
  bucket = aws_s3_bucket.chat.id

  rule {
    id     = "abort-incomplete-chat-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
