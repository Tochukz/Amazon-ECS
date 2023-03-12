# Amazon Elastic Container Service (AWS ECS)
[ECS Docs](https://docs.aws.amazon.com/ecs/index.html)   
[Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)  
[Fargate User Guide](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html)  
[CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ecs/index.html)  
[Pricing](https://aws.amazon.com/ecs/pricing/)   
[ECS Tutorials](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-tutorials.html)  
[ECS Workshop](https://ecsworkshop.com/)

## Chapter 1: Introduction
### Setup
__Create a VPC Only__  
```
$ aws ec2 create-vpc --cidr-block 10.0.0.0/16
```  
#### CLI Tools
__AWS Copilot__   
AWS Copilot is used to build, release, and operate containerized applications on Amazon ECS, and AWS Fargate.
To install AWC copilot, use home brew
```
$ brew install aws/tap/copilot-cli
$ copilot --help
```
[Copilot CLI](https://aws.github.io/copilot-cli/)

__AWS ECS-CLI__  
ECS CLI is an older alternative to _Copilot_. It provides high-level commands to simplify creating, updating, and monitoring clusters and tasks from a local development environment. The Amazon ECS CLI supports Docker Compose files.  
To install ECS CLI, use home brew
```
$ brew install amazon-ecs-cli
$ ecs-cli --help
```  
To configure ECS CLI
```bash
# configure a profile for access
$ ecs-cli configure profile --profile-name chucks1 --access-key XXXXXXXXXXXXXXX --secret-key XXXXXXXXXXXXXXXXX  
# configure a cluster
$ ecs-cli configure --cluster plus1-cluster --default-launch-type FARGATE --region eu-west-2 --config-name chucks1-config  
# create the cluster
$ ecs-cli up
```  
Configuration information is stored in the `~/.ecs` directory on macOS and Linux systems and in `C:\Users\<username>\AppData\local\ecs` on Windows systems.  
ecs-cli will create the name of the cluster specified if it does not already exist.  

__Common ecs-cli commands__  

Command         | Description
----------------|-------------
`ecs-cli ps`    | List the running containers in the cluster
`ecs-cli images`| Lists images from an ECR repository.

#### Introduction   
Amazon Elastic Container service is a highly scalable, fast, container management service that makes it easy to run, stop, and manage Docker containers on a cluster.
It is comparable to Kubernetes, Docker Swarm, and Azure Container Service.  

__Launch Types__  
There are three models that you can use to launch your container:  
1. Fargate launch type - This is a serverless pay-as-you-go options
2. EC2 launch type - Configure and deploy EC2 instances in your cluster to run your container
3. Amazon ECS on AWS Outposts -

### Amazon ECS Components
__Clusters__   
A cluster is a logical grouping of tasks or services.  
__Docker containers and images__  
To deploy applications on Amazon ECS, your application components must be configured to run in containers.   
Containers are created from a read-only template that's called an image.
Images are typically built from a _Dockerfile_.   

__Tasks__  
A task is an instance of a task definition within a cluster. It runs the container defined within the task definition. Multiple tasks can be created from one task definition as needed.  
It is the lowest level building block of ECS. Think of tasks as runtime instances.   

__Task definitions__   
A task definition is a text file that describes one or more containers that forms your application. It is in YAML or JSON format. Think of task definitions as template or blueprint for your task. It contains settings like exposed port, docker image, cpu shares, memory requirement, command to run and environmental variables.

__Services__   
A service is used to manage one or more Tasks of the same Task definition.
You can use an ECS service to run and maintain your desired number of tasks simultaneously in an
ECS cluster.   
With a service, you can do autoscaling and load balancing for example, when a Task max out it CPU, the service can add a new Task.  

__ECS Container__  
An ECS container is an EC2 instance running Docker and ECS container agent.

__ECS Cluster__  
An ECS cluster is a group of ECS container instances.  
 A cluster may contain one or more tasks.   
![ECS Cluster](https://cdn-media-1.freecodecamp.org/images/scH1QJHgrQ6NgA1jQo9ITuCiQGkAawRHmzSc)  

__ECS Container Instance__  
An ECS container instance is an EC2 instance that has Docker and ECS Container Agent running on it.  A Container Instance can run many Tasks, from the same or different Services. A group of container instances makes up an ECS cluster.  

__Container agent__   
The container agent runs on each ECS container instance within an Amazon ECS cluster. The Agent takes care of the communication between ECS and the ECS instance, providing the status of running containers and managing running new ones.

__Summary of terms__  

Term            | Description
----------------|-------
Docker container| A package containing the application code, configuration and dependencies
Docker Image    | A template which describes a container
Task            | A runtime instance of the app. It can contain one or more containers.
Task definition | A template that defines a task
Service         | A collection of tasks of the same type
A service and span multiple ECS container instances
ECS Container   | An EC2 instance with Docker engine and ECS Container Agent installed
ECS Cluster     | A group of ECS Container instances

[A beginner’s guide to Amazon’s Elastic Container Service](https://www.freecodecamp.org/news/amazon-ecs-terms-and-architecture-807d8c4960fd/)

#### Setup
__Setup for AWS ECS__   
1. Install AWS CLI  
2. Create a keypair  
For Amazon ECS, a key pair is only needed if you intend on using the EC2 launch type.  
    ```
    $ aws ec2 create-key-pair --key-name MyLinuxKey --query "KeyMaterial" --output text > MyLinuxKey.pem
    $ chmod 400 MyLinuxKey.pem
    ```  
    You may store you keypair with AWS SecretsManger for long-term use.  
    ```
    $ aws secretsmanager create-secret --name MyLinuxKey --description "Amazon linux key" --secret-string $(base64 MyLinuxKey.pem)
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
    $ aws ec2 authorize-security-group-ingress --group-id sg-your-id --protocol tcp --port 22 --cidr 0.0.0.0/0
    $ aws ec2 authorize-security-group-ingress --group-id sg-your-id --protocol tcp --port 80 --cidr 0.0.0.0/0
    $ aws ec2 authorize-security-group-ingress --group-id sg-your-id --protocol tcp --port 443 --cidr 0.0.0.0/0
    ```  
    If you plan to launch container instances in multiple Regions, you need to create a security group in each Region.

## Chapter 2: ECS Container Images
[Deploy Docker Containers on ECS](https://docs.docker.com/cloud/ecs-integration/)  
__Prerequisite__    
1. Install Docker desktop on you local machine from [docker desktop](https://docs.docker.com/desktop/).  
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
    The `docker build` command must be run in the root directory where `Dockerfile` is present.  
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
Let's publish the newly created image to Amazon Elastic Container Registry.   

1. Create an ECR repository

    ```
    $ aws ecr create-repository --repository-name hello-repository
    ```
    Copy the `repositoryUri` from the result.   
    To see all your repository do
    ```
    $ aws ecr describe-repositories
    ```  
2. Tag the hello-word image with the repository URI

    ```
    $ docker tag hello-world my-repository-uri
    ```
    Replace `my-repository-uri` with you actual repository URI.
3. Authenticate the repository URI using the `get-login-password` `erc` subcommand.
    ```
    $ docker login -u AWS -p $(aws ecr get-login-password) my-repository-uri
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
By default, your account receives a default cluster when you launch your first container instance, but you can create your own cluster.
    ```
    $ aws ecs create-cluster --cluster-name FargateCluster
    ```  
    If you are using your default cluster, you will not need to pass the `--cluster-name` flag at all.  
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
    You can use your default cluster or create your own custom cluster
    ```
    $ aws ecs create-cluster --cluster-name MyCluster
    ```  
    NB: because you have created a non-default cluster, you cannot use the default cluster anymore and must specify your cluster name using the `--cluster` flag in the relevant `ecs` command.  
2. Create an IAM role and attach the `AmazonEC2ContainerServiceforEC2Role` policy.
    ````
    $ aws iam create-role --role-name ECSContainers --assume-role-policy-document file://trust-policy.json
    $  aws iam attach-role-policy --role-name ECSContainers --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
    ````
    You can get the ARN of the managed policy from the IAM console.  
3. Create an instance profile and add the IAM role to the profile
    ```
    $ aws iam create-instance-profile --instance-profile-name ECSInstanceProfile
    $ aws iam add-role-to-instance-profile --role-name ECSContainers --instance-profile-name ECSInstanceProfile
    ```
4. Search for an ECS Optimized AMI  
  * Go to AWS EC2 console and click on Launch Instance  button.   
  * Scroll to the _Application and OS images_ section and click on _Browse more AMIs_.
  * Enter the search text `ami-ecs` and search.   
  * Click on the search result and select an AMI and go through it's details.
  * Copy the AMI's name of you chosen AMI e.g `amzn2-ami-ecs-hvm-2.0.20220921-x86_64-ebs`
  * Get the details of the AMI
    ```
    $ aws ssm get-parameters /aws/service/ecs/optimized-ami/amazon-linux-2/[ami-name]
    ```
    Where `[ami-name]` is the AMI name.  
    For example
    ```
    $ aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/amzn2-ami-ecs-hvm-2.0.20220921-x86_64-ebs
    ```
    Copy the value of the `image_id` from the result
  * Alternatively you can get the AMI of the latest Amazon ECS-optimized Amazon Linux 2 AMI
    ```
    $ aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended
    ```
    Copy the value of the `image_id` from the result.  
    For windows OS and other ECS optimized AMI see [Retrieving Amazon ECS-Optimized AMI metadata](https://docs.amazonaws.cn/en_us/AmazonECS/latest/developerguide/retrieve-ecs-optimized_windows_AMI.html).  
5. Launch an EC2 Instance with the ECS optimized AMI
  * Launch an EC2 instance using an ECS optimized AMI image Id from the previous step and the IAM instance profile created earlier
    ```
      $ aws ec2 run-instances --image-id ami-02bfd81009b599d71 --subnet-id subnet-0dfa1925f4155b859 --instance-type t2.micro --key-name AmzLinuxKey2 --security-group-ids sg-097302308e8550121 --iam-instance-profile Name=ECSInstanceProfile
    ```
  * By launching your ECS instance with an ECS optimized AMI, you get `docker` and _ECS container agent_ installed by default. You can ssh into your EC2 instance and check
    ```
    $ sudo service docker status
    $ sudo service ecs status
    ```  
    If you used a regular AMI, you will have to install docker and the ECS container agent yourself.  
  * If you already have an existing ECS instance, you can associate the IAM instance profile from the earlier step with the EC2 instance
    ```
    $ aws ec2 associate-iam-instance-profile --instance-id i-0f999e6d4637 --iam-instance-profile Name=ECSInstanceProfile
    $ aws ec2 describe-iam-instance-profile-associations
    ```
    Alternatively, you can attach IAM role directly to the exiting ECS instance.   
    ```
    $ aws ec2 associate-iam-instance-profile --instance-id i-xxxxxxxxx --iam-instance-profile Name="RoleName"
    ```
6. (Optional) ssh into your instance and create the ECS container agent config file `/etc/ecs/ecs.config` with the content.
    ```bash
    # containers will now launch into MyCluster instead of the default cluster.
    # For default cluster you don't need this variable.
    ECS_CLUSTER=MyCluster
    # tags for your container instance
    ECS_CONTAINER_INSTANCE_TAGS={"tag_key": "tag_value"}
    ```
    This is better done with a user script during launch time if possible.   
    After doing this, you may need to restart the ECS container agent
    ```
    $ sudo service ecs restart
    ```
    See [ECS container agent configuration](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html) for more ECS container agent configuration options.
7. List containers instances in your cluster
    ```
    $ aws ecs list-container-instances --cluster MyCluster
    ```
    If you are using the default cluster you may omit the `--cluster` flag.
    The container instance ID is the substring after the cluster name of the container instance ARN.  
    To get valuable information about the container instance, use the container instance ID:
    ```
    $ aws ecs describe-container-instances --cluster MyCluster --container-instances 6f6fa62409f14b03a93d75a24f65ec2e
    ```
8. Register a task definition
   ```
   $ aws ecs register-task-definition --cli-input-json file://nginx-task.json
   $ aws ecs list-task-definitions  
   ```
9. Run task
   ```
   $ aws ecs run-task --cluster MyCluster --task-definition nginx:1 --count 1
   $ aws ecs list-tasks --cluster MyCluster
   ```
   The `task-definition` value should be the last segnment og the taskDefinitionArn resulting from the `register-task-definition` output.

[Gentle Introduction to How AWS ECS Works with Example Tutorial](https://medium.com/boltops/gentle-introduction-to-how-aws-ecs-works-with-example-tutorial-cea3d27ce63d)

### Useful operations.
__To install AWS CLI in AmazonLinux 2__  
install aws-cli
sudo yum install -y aws-cli


__To access the ECS agent log__   
```bash
# SSH into you ECS instance and copy the ecs-agent.log file to home directory
$ cp /var/log/ecs/ecs-agent.log copy-ecs-agent.log
# Copy the copy-ecs-agent.log to you local machine
scp -i ~/MyKeyPair.pem ec2-user@xx.xxx.x.xx:~/copy-ecs-agent.log ecs-agent.log
```

__To See the policies attached to a role__  
```
$ aws iam list-attached-role-policies --role-name ecs-instances
```

__Resources__  
[Example task definition](https://docs.aws.amazon.com/AmazonECS/latest/userguide/example_task_definitions.html)   
[AWS Sample task definitions](https://github.com/aws-samples/aws-containers-task-definitions)   
[Task definition parameters](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task_definition_parameters.html)
