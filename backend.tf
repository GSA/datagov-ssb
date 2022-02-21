terraform {
  backend "s3" {
    bucket    = var.backend_s3_bucket_name
    key       = var.backend_s3_key
    region    = var.backend_s3_region
    encrypted = var.backend_s3_encrypted
    profile   = var.backend_s3_profile
  }
}
