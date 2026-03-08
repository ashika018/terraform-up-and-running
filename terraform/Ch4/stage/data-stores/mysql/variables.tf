# ユーザー名、パスワードの変数を設定
# sensitive = trueにより、Terraformの出力やログに値が表示されないようにする

variable "db_username" {
  description = "The username for the MySQL database"
  type = string
  sensitive = true
}

variable "db_password" {
  description = "The password for the MySQL database"
  type = string
  sensitive = true
}