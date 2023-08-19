variable "db_password" {
  type = string 
  description = "Password for the RDS instance"
}
# variable "repository_url" {
#   type = string
#   description = "The URL of the repository"
# }
variable "repository_name" {
  type = string
  description = "The name of the ECR repository"
}
variable "container_name" {
  type = string 
  description = "Name for the application container"
}