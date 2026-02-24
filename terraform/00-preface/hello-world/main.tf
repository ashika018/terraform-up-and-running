provider "aws" {
  region = "ap-northeast-1"
  profile = "ashika018"
}

resource "aws_instance" "example"{
  ami = "ami-088103e734f7e0529"
  instance_type = "t2.micro"

  tags = {
    Name = "terraform.example"
  }
}