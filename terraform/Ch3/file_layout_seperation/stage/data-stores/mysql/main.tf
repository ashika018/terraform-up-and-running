provider "aws" {
  region = "ap-northeast-1"
  profile = "ashika018"
}

terraform {
  backend "s3" {
    region = "ap-northeast-1"
    profile = "ashika018"

    bucket = "terraform-state-ashika018"
    key = "stage/data-stores/mysql/terraform.tfstate" # stateファイルの保存場所
    use_lockfile = true
    encrypt = true
  }
}

# ---------------------------
# RDS
# ---------------------------
resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t3.micro"
  skip_final_snapshot = true
  db_name = "example_database"

  # ユーザ名とパスワードは環境変数から渡す
  username = var.db_username
  password = var.db_password
}