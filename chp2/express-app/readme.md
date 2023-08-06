# Containerized ExpressJS application
## Setup 
Build the image 
```bash
$ docker build -t bbdchucks/express-app .
```
Run a container 
```bash
$  docker run -p 8080:3000 --name express-app-0.0.1 -it bbdchucks/express-app
```
Visit localhost:8080 on the browser window to test the running application.  
Press _ctrl+P_ followed by _ctrl+Q_ to quite the interactive mode. 

## Publish docker image
__Docker HUB__  
To publish your docker image to the Docker hub
```bash
$ docker push bbdchucks/express-app
```

__AWS ECR__  
To publish your docker image to AWS ECR: 
First create repository 
```bash
$ aws ecr create-repository --repository-name express-app
``` 
Tag the image using the _repositoryUri_ obtained from the result of the _create-repository_ action. 
```bash 
$ docker tag bbdchucks/express-app 665778208875.dkr.ecr.eu-west-2.amazonaws.com/express-app
```
Login to ECR using the following command `docker login -u AWS -p $(aws ecr get-login-password --region REGION) aws_account_id.dkr.ecr.REGION.amazonaws.com`.
Remeber to replace _aws_account_id_ with your account id and _REGION_ with your AWS region.  

```bash
$ docker login -u AWS -p $(aws ecr get-login-password --region eu-west-2) 665778208875.dkr.ecr.eu-west-2.amazonaws.com
```
Repace aws_account_id and REGION with your account id and region respectively.  
Push the image to ECR 
```bash
$ docker push 665778208875.dkr.ecr.eu-west-2.amazonaws.com/express-app
```

## Clean up 
Stop the container and delete it 
```bash
$ docker stop express-app-0.0.1
$ docker rm express-app-0.0.1 
```
Delete the ECR repository to avoid charges, 
```
$ aws ecr delete-repository --repository-name express-appp  --force
```