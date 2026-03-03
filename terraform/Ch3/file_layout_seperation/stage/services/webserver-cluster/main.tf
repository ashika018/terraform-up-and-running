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
    key = "stage/services/webserver-cluster/terraform.tfstate" # stateファイルの保存場所
    # dynamodb_table = "terraform-locks-ashika018"
    use_lockfile = true
    encrypt = true
  }
}

# ---------------------------
# 他で構築（もしくはデフォルトで構築）したもののデータを取得
# ---------------------------
data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
      name = "vpc-id"
      values = [ data.aws_vpc.default.id ]
    }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    region = "ap-northeast-1"
    profile = "ashika018"

    bucket = "terraform-state-ashika018"
    key = "stage/data-stores/mysql/terraform.tfstate"
  }
}

# ---------------------------
# EC2
# ---------------------------
resource "aws_launch_template" "example" {
  name_prefix = "terraform-asg-example-"
  image_id = "ami-0f65fc8c24ec8d2a1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.instance.id ]

  user_data = base64encode(templatefile("user-data.sh", {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }))

  # Autoscaling Groupがある起動設定を使った場合に必須
  lifecycle {
    create_before_destroy = true
  }
}

# オートスケーリング
resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id = aws_launch_template.example.id
    version = "$Latest"
  }

  target_group_arns = [ aws_lb_target_group.asg.arn ]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# ---------------------------
# ALB
# ---------------------------
resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [ aws_security_group.alb.id ]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  # デフォルトではシンプルな404ページを返す
  default_action {
  type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = [ "*" ]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# ---------------------------
# SG
# ---------------------------
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # インバウンド
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンド
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}