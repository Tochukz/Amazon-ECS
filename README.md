# Amazon Elastic Container Service (AWS ECS)
[Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)  
[Pricing](https://aws.amazon.com/ecs/pricing/)   
[Amazon ECS Tutorials](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-tutorials.html)

## Chapter 1: Introduction
__Launch Types__  
There are two models that you can use to launch your container:  
1. Fargate launch type - This is a serverless pay-as-you-go options
2. EC2 launch type - Configure and deploy EC2 instances in your cluster to run your container

#### Amazon ECS Components
__Clusters__   
An Amazon ECS cluster is a logical grouping of tasks or services.

__Containers and images__  
To deploy applications on Amazon ECS, your application components must be configured to run in containers.   
Containers are created from a read-only template that's called an image.
Images are typically built from a Dockerfile.  

__Tasks__  
A task is the instantiation of a task definition within a cluster.
It is the lowest level building block of ECS. Think of tasks as a  runtime instances.

__Task defintions__   
A task definition is a text file that describes one or more containers that form your application. It is in JSON format. Think of task definitions as template or blueprint for your task.

__Services__   
You can use an Amazon ECS service to run and maintain your desired number of tasks simultaneously in an Amazon ECS cluster.   

__Container agent__   
The container agent runs on each container instance within an Amazon ECS cluster.   


#### Setup
__Seup for AWS ECS__  
1. Install AWS CLI
2. Create a keypair  
For Amazon ECS, a key pair is only needed if you intend on using the EC2 launch type.  
```
$ aws ec2 create-key-pair --key-name MyLinuxKey --query "KeyMaterial" --output text > MyLinuxKey.pem
$ chmod 400 MyLinuxKey.pem
```  
You may store you keypair with AWS SecretsManger for longterm use.  
```
 $ aws secretsmanager create-secret --name AmazonLinux4 --description "Amazon linux key" --secret-string $(base64 MyLinuxKey.pem)
```  

 If you plan to launch instances in multiple regions, you'll need to create a key pair in each region.


 3. Create a Virtual Private Cloud
 The CIDR block size must have a size between /16 and /28.
 ```
$ aws ec2 create-vpc --cidr-block 10.0.0.0/16
 ```

4. Create Security group   
```
$ aws ec2 create-security-group --group-name linux-sg --description "Security Group for My Linux Instances" --vpc-id vpc-your-id
```
5. Add some rules to the security group
```
aws ec2 authorize-security-group-ingress --group-id sg-your-id --protocol tcp --port 22 --cidr 0.0.0.0/0
$ aws ec2 authorize-security-group-ingress --group-id sg-your-id --protocol tcp --port 80 --cidr 0.0.0.0/0
```  
If you plan to launch container instances in multiple Regions, you need to create a security group in each Region.

## Chapter 2: ECS Container Images
[Deploy Docker Containers on ECS](https://docs.docker.com/cloud/ecs-integration/)  
__Prerequisite__    
1. Install Docker desktop on you local machine from [docker desktop](https://docs.docker.com/desktop/)
After installation check your terminal
```
$ docker --version
```
2. Install Docker on Amazon Linux2
```bash
$ sudo yum update -y
$ sudo amazon-linux-extras install docker
$ sudo service docker start
# to make docker start on system reboot
$ sudo systemctl enable docker
# to not always use sudo, add the ec2-user to docker group
$ sudo usermod -a -G docker ec2-user
```  
You may need to logout from the SSH session and login again to be able to use the docker without sudo.  
In some cases, you may need to reboot your instance to provide permissions for the ec2-user to access the Docker daemon.

__Create a docker image__  
Here we create a docker image for a simple web application.  
1. Create the docker file. See sample at `chp2/Dockerfile`
2. Build the docker image from the docker file
```
$ cd chp2
$ docker build -t hello-world .
```
3. Check to see that the docker image was created successfully
```
$ docker images --filter reference=hello-world
```
4. Run the docker image
```
$ docker run -i -t -p 80:80 hello-world
```  
This maps port 80 front aside the container to port 80 inside the container.
5. Launch your favourite browser and enter `http://localhost/`  
You can stop the docker container by press `ctrl+C`.  

__Publish docker image to ECR__  
Let publish the newly created image to Amazon Elastic Container Registry.   
1. Create and ECR repository
```
$ aws ecr create-repository --repository-name hello-repository
```
Copy the `repositoryUri` from the result. To see all your repository
```
$ aws ecr describe-repositories
```  
2. Tag the hello-word image with the repository URI
```
$ docker tag hello-world my-repository-uri
```
3. Authenticate to the repository URI using the `get-login-password` `erc` subcommand.
```
docker login -u AWS -p $(aws ecr get-login-password) my-repository-uri
```  
You should get the output `Login Succeeded`
4. Push the image to ECR using the repository URI
```
$  docker push my-repository-uri
```
5. After you are done, delete the repository so you are not charged for image storage
```
$ aws ecr delete-repository --repository-name hello-repository --force
```


## Chapter 3: Creating a cluster with a Fargate Linux task
1. Create your cluster  
```
$ aws ecs create-cluster --cluster-name FargateCluster
```
You may use your account's default cluster, and there will be no need to pass the `--cluster-name` flag in any command.  
2. Register a task definition    
A task definition is a list of containers grouped together. See the sample task definition in `chp3/fargate-task.json`.  
To create the task definition
```
$ aws ecs register-task-definition --cli-input-json file://fargate-task.json
```
To see all your task definitions
```
$ aws ecs list-task-definitions
```  
And the view the details of your task definition
```
$ aws ecs describe-task-definition --task-definition sample-fargate
```
`sample-fargate` is the `family` value as defined in the json file.  
3. Create VPC and public/private subnets
4. Create a service  
To create a service for your registered task to have access to the internet, you can do it in two ways:   
 - use a public subnet and assign a public IP address to your task.
 ```
$ aws ecs create-service --cluster FargateCluster --service-name FargateService --task-definition sample-fargate:1 --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-0dfa1925f4155b859],securityGroups=[sg-097302308e8550121],assignPublicIp=ENABLED}"
 ```
 - use a private subnet configured with a NAT gateway with an elastic IP address in a public subnet
 ```
$ aws ecs create-service --cluster fargate-cluster --service-name fargate-service --task-definition sample-fargate:1 --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-abcd1234],securityGroups=[sg-abcd1234]}"
 ```
 You can list all the services available in your cluster
 ```
$ aws ecs list-services --cluster FargateCluster
 ```
You can view the details of you service
```
$ aws ecs describe-services --cluster FargateCluster --service FargateService
```

5. Get public IP address of your task
```bash
$  aws ecs list-tasks  --cluster FargateCluster --service FargateService
# Use the arn of the task to obtain details of the task
$ aws ecs describe-tasks --cluster FargateCluster --task arn:aws:ecs:eu-west-2:966727776968:task/FargateCluster/ca81eaa9d34c4de68b7d3cf99d0f400f
# Describe the ENI using the networkInterfaceId eni-xxxxxxxxx
$ aws ec2 describe-network-interfaces --network-interface-id eni-0712f2212b5d48ab7  
# The output contains the public IP address
```  
6. Clean up  
To avoid charges, delete the service and the cluster
```
$  aws ecs delete-service --cluster FargateCluster --service FargateService --force
$ aws ecs delete-cluster --cluster FargateCluster
```  

## Chapter 4: Creating a cluster with an EC2 task
1. Create a cluster
```
$ aws ecs create-cluster --cluster-name MyCluster
```
2. Launching an Amazon ECS Linux container instance
