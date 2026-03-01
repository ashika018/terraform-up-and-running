provider "aws" {
  region = "ap-northeast-1"
  profile = "ashika018"
}

# .tfstateファイルの保存場所をS3に設定
terraform {
  backend "s3" {
    region = "ap-northeast-1"
    profile = "ashika018"

    bucket = "terraform-state-ashika018"
    key = "global/s3/terraform.tfstate" # stateファイルの保存場所
    # dynamodb_table = "terraform-locks-ashika018"
    use_lockfile = true
    encrypt = true
  }
}

# ---------------------------
# S3
# ---------------------------

# バケット本体
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-ashika018"
  lifecycle {
    prevent_destroy = true
  }
}

# バケットのバージョニングを有効化
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# サーバーサイド暗号化の設定
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスのブロック
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# ---------------------------
# DynamoDB(2024年以前はStateLock用に必要出会ったが、2024年以降は不要になった)
# ---------------------------
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "terraform-locks-ashika018"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }