# Deploy your Apache Web Server in AWS with Terraform
<p float="center">
<img src="https://www.datocms-assets.com/58478/1640019487-og-image.png" height="100">
<img src="https://niixer.com/wp-content/uploads/2020/11/5-1-1.png" height="100">
</p>

This project is a basic example of how to deploy a Web Server in AWS using Terraform.


## Quick start guide
<mark>In case you already have terraform installed, make sure you update it before attempting to deploy the infrastructure.</mark>

You can download Terraform from [here](https://www.terraform.io/downloads).

### Steps
Inside the folder with both .tf and .tfvars files run:
```bash
 terraform init
 ```
Once done, the AWS pluggin will be installed. Then, execute
```bash
 terraform apply
 ```
 and enter your AWS access key and secret key in order to deploy the infrastructure in your AWS account.
 
 When you are done using the insfrastructure, run
 ```bash
terraform destroy
 ```
 to release all AWS services used.
