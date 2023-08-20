variable "ssh_allowed_cidr" {
  type = string
  description = "cidr block to allow SSH access"
}
variable "http_allowed_cidr" {
  type = string
  description = "cidr block to allow HTTP/HTTPS access"
}
variable "jwt_secret" {
  type = string
  description = "JWT secret"
}