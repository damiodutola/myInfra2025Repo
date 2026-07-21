resource "aws_s3_bucket" "my-dev-tf-state-bucket-2026" {
  bucket_prefix = var.bucket_prefix
  acl = var.acl
  
   versioning {
    enabled = var.versioning
  }
  
  tags = var.tags
}
