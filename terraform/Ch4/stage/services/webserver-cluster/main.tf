provider "aws" {
  region = "ap-northeast-1"
}

module "webserver_cluster" {
  source = "../../module/services/webserver-cluster"

  cluster_name = "webservers-stage"
  db_remote_state_bucket = "terraform-state-ashika018"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}
