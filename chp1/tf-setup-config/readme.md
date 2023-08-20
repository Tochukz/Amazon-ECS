## Setup
__Create a keypair__  
A public key file is required for the _aws_key_pair_ resource. 
You can generate a keypair as follows: 
```bash
$ mkdir keys
$ ssh-keygen -q -f keys/setup -C aws_terraform_ssh_key -N ''
``` 
This generates a keypair name _setup_ in the _keys_ directory. 

## Important note 
__Region__ 
If you plan to launch container instances in multiple Regions, you need to create a security group in each Region. 
__Security group cidr__ 
It is acceptable for a short time in a test environment, to permit traffic from anywhere by using the open CIDR block _0.0.0.0/0_ in your security group but it's unsafe in production environments.  
In production, authorize only a specific IP address or range of addresses to access your instance.  
For example, for SSH access, specify the public IP address of your computer or network in CIDR notation. To specify an individual IP address in CIDR notation, add the routing prefix /32. For example, if your IP address is 203.0.113.25, specify 203.0.113.25/32. If your company allocates addresses from a range, specify the entire range, such as 203.0.113.0/24.  

## Prepare and deploy 
Run linting and security check on the configuration 
```bash
$ tflint 
$ tfsec --tfvars-file dev.tfvars
``` 
Run terraform init if you have not ye deployed the configuration before
```bash 
$ terraform init 
```
Run terraform plan 
```bash 
$ terraform plan --var-file dev.tfvars 
```
Run terraform apply 
```bash 
$ terraform apply --var-file dev.tfvars 
```  
