# output "mysql_endpoint" {
#   value = aws_db_instance.mysql.endpoint
# }

# output "ecr_repository_url" {
#   value = aws_ecr_repository.cluster_respositoy.repository_url
# }

output "lb_dns_name" {
  value = aws_lb.cluster_lb.dns_name
}