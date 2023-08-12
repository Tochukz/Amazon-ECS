# ECS Cluster of EC2 Instances 
[Original Source](https://medium.com/@paweldudzinski/creating-aws-ecs-cluster-of-ec2-instances-with-terraform-893c15d1116)  
[Copied Source](https://medium.com/swlh/creating-an-aws-ecs-cluster-of-ec2-instances-with-terraform-85a10b5cfbe3)  

### Description 
Within a VPC there’s an autoscaling group with EC2 instances. 
ECS manages starting tasks on those EC2 instances based on Docker images stored in ECR container registry. 
Each EC2 instance is a host for a worker that writes something to RDS MySQL. 
EC2 and MySQL instances are in different security groups.


### Before deployment
#### Setup
