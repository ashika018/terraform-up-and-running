provider "aws" {
  region = "ap-northeast-1"
}

module "webserver_cluster" {
  source = "../../module/services/webserver-cluster"

  cluster_name = "webserver-prod"
  db_remote_state_bucket = "terraform-state-ashika018"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "m4.large"
  min_size = 2
  max_size = 10
}

resource "aws_autoscaling_schedule" "scale_out_hours" {
  scheduled_action_name = "scale-out-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * 1-5" # 毎週月曜から金曜の午前9時にスケールアウト

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_hours" {
  scheduled_action_name = "scale-in-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 18 * * 1-5" # 毎週月曜から金曜の午後6時にスケールイン

  autoscaling_group_name = module.webserver_cluster.asg_name
}