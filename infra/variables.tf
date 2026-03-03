variable "project"    { type = string }              # prefijo para nombrar recursos
variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "app_name"   {
  type = string
  default = "demo-backend-app"
}
variable "env_name"   {
  type = string
  default = "demo-backend-env"
}