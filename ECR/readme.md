# Amazon Elastic Container Registry (ECR)
[ECR Docs](https://docs.aws.amazon.com/ecr/?icmpid=docs_homepage_containers)  
[User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)  
[API Reference](https://docs.aws.amazon.com/AmazonECR/latest/APIReference/Welcome.html)  
[CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ecr/index.html)    

### Introduction  
Amazon ECR supports private repositories with resource-based permissions using AWS IAM.
Amazon ECR supports public container image repositories as well. For more information, see What is [Amazon ECR Public](https://docs.aws.amazon.com/AmazonECR/latest/public/what-is-ecr.html).  

You can use your preferred CLI to push, pull, and manage Docker images, _Open Container Initiative_ (OCI) images, and OCI compatible artifacts.

__Components of Amazon ECR__
1. __Registry__: You can create one or more repositories in your registry and store images in them.
2. __Authorization token__: Your client must authenticate to Amazon ECR registries as an AWS user before it can push and pull images.
3. __Repository__: An ECR repository contains your Docker images, _Open Container Initiative_ (OCI) images, and OCI compatible artifacts.  
4. __Repository policy__: You can control access to your repositories and the images within them with repository policies.
5. __Image__: You can push and pull container images to your repositories. You can use these images locally on your development system, or you can use them in Amazon ECS task definitions and Amazon EKS pod specifications.

__Features of ECR__  
1. Lifecycle policy
2. Image scanning
3. Cross-Region and cross-account replication
4. Pull through cache rules

### Getting started
__To install Docker on an Amazon EC2 instance__  
For EC2 instance running Amazon Linux 2 AMI   
```bash
$ sudo yum update -y
$ sudo amazon-linux-extras install docker
# start the docker service
$ sudo service docker start
# to execute docker command without sudo, add ec2-user to docker group
$ sudo usermod -a -G docker ec2-user
```  
Logout of the EC2 instance and log back in for the ec2-user addedd to docker group to take effect.  
```
$ docker info
```  
If you get an error, you may need to reboot you instance.

__Create docker image__  
1. Create a _Dockerfle_
2. Build a docker image from the docker file.
```
$ docker build . -t chucks/apache-app
```
3. Check that the docker image was built
```
$ docker images --filter reference=chucks/apache-app
```
4. Run the docker image and test to make sure it works
```bash
$ docker run -p 8050:80 -d chucks/apache-app
# check that the container is running
$ docker ps
# Test the apache server
$ curl -i http://localhost:8050
```
5. Kill the docker container
```bash
# find the container Id
$ docker ps  
$ docker kill 0bdc16982d3c  
```  

__Authenticate Docker CLI to your default ECR registry__   
1. Get you AWS account Id
```
$ aws sts get-caller-identity
```
2. Authenticate Docker CLI using `ecr get-login-password`
```
aws ecr get-login-password | docker login --username AWS --password-stdin xxxxxx.dkr.ecr.eu-west-2.amazonaws.com
```  
Replace _xxxxxx_ with you actual account Id from step 1 and _eu-west-2_ with your chosen region.  
You should get a result that says _Login Succeeded_.  
3. Create a repository  
```
$ aws ecr create-repository --repository-name apache-app --image-scanning-configuration scanOnPush=true   
$ aws ecr describe-repositories
```  

__Push an image to your repository__  
1. Find the image you want to push
```
$ docker images
```  
2. Tag the image you want to push
```
$ docker tag chucks/apache-app:latest xxxxxx.dkr.ecr.eu-west-2.amazonaws.com/apache-app
```
Replace _xxxxxx_ with your actual account Id and _eu-west-2_ with you chosen region.  
3. Push the image  using the tag
```
$ docker push xxxxxx.dkr.ecr.eu-west-2.amazonaws.com/apache-app
$ aws ecr list-images --repository-name apache-app
```

__Pull an image from your repository__  
```
$ docker pull xxxxxx.dkr.ecr.eu-west-2.amazonaws.com/apache-app:latest  
$ docker images
```

__Delete an image from your repository__  
```bash
$ aws ecr batch-delete-image --repository-name apache-app --image-ids imageTag=latest
$ aws ecr list-images --repository-name apache-app
```
__Delete your repository__  
```
$ aws ecr delete-repository --repository-name apache-app
```
