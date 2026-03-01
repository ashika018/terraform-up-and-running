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
    # workspace = defaultでのstateファイルの保存場所
    # workspace = defaultでない場合、env:/workspace名/workspac-example/terraform.tfstateに保存される
    key = "workspace-example/terraform.tfstate" 
    # dynamodb_table = "terraform-locks-ashika018"
    use_lockfile = true
    encrypt = true
  }
}

# ---------------------------
# EC2
# ---------------------------
resource "aws_instance" "example" {
  ami = "ami-0f65fc8c24ec8d2a1"
  instance_type = "t2.micro"
}