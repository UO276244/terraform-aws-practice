provider "aws" {
    region="us-east-1"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

variable "aws_access_key" {
    type = string
}

variable "aws_secret_key" {

    type = string
  
}

#HOW TO DEFINE VARIABLES WITHIN .tf FILES --> Other way is to use terraform.tfvars file

variable "private_ip_in_subnet" {

    #if default value is not assigned here, we will be asked to provide a value in the console
    #default = "10.0.1.50" --> Assigned in .tfvars file
    type = string
    description = "value of private IP"
}

variable "subnet_prefix" {

    description = "Lists of subnet prefixs"

}

#1 - Create VPC

resource "aws_vpc" "main-vpc" {

    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "Main-VPC"
    }
}

#2 - Create Internet Gatway - to allow anyone can reach the server through a public IP

resource "aws_internet_gateway" "main-gw" {

    vpc_id = aws_vpc.main-vpc.id
    tags = {
        Name = "GW-1"
    }

}

#3 - Create Custom Route Table

resource "aws_route_table" "main-route-table"{ 

    vpc_id = aws_vpc.main-vpc.id

    route {
        #Route ALL network traffic through the gateway
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main-gw.id
    }

    route {
        #Route ALL network traffic through the gateway
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.main-gw.id
    }

    tags = {
        Name = "Main-RouteTable"
    }
}

#4 - Create a Subnet

resource "aws_subnet" "subnet-1" {

    vpc_id = aws_vpc.main-vpc.id
    cidr_block = var.subnet_prefix[0].cidr_block

    availability_zone = "us-east-1a"

    tags = {
        Name = var.subnet_prefix[0].name
    }

}

#4.5 another subnet just for testing lists

resource "aws_subnet" "subnet-2" {

    vpc_id = aws_vpc.main-vpc.id
    cidr_block = var.subnet_prefix[1].cidr_block

    availability_zone = "us-east-1a"

    tags = {
        Name = var.subnet_prefix[1].name
    }

}

#5 - Associate subnet with Route Table

resource "aws_route_table_association" "rt-assoc-1" {

    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.main-route-table.id


}


#6 - Create a Security Group to allow port 22,80 and 443 - determine what trafic is allowed in our EC2 instances

resource "aws_security_group" "main-sec-group"{
    name = "allow_web_traffic"
    description = "Allow inbound SSH and HTTP(s) traffic."
    vpc_id = aws_vpc.main-vpc.id

    #Allow inbound traffic in port 443
    ingress {
        description = "Allow inbound HTTPS traffic to 443"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow inbound HTTP traffic to 80"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow inbound SSH traffic to 22"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" #Any protocol
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Allow_WEB"
    }

}


#7 - Create a network interface with an IP in the subnet creared in step 4

resource "aws_network_interface" "net-interface-1" {

    subnet_id = aws_subnet.subnet-1.id
    private_ips = [var.private_ip_in_subnet] #Private IP inside the subnet-1
    security_groups = [aws_security_group.main-sec-group.id]
}

#8 - Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "elastic-ip-1" {
    vpc = true
    network_interface = aws_network_interface.net-interface-1.id
    associate_with_private_ip = var.private_ip_in_subnet

    #AWS does not allow to deploy an Elastic IP within a VPC without a GateWay, so
    #EIP must depend on it.
    depends_on = [
      aws_internet_gateway.main-gw
    ]
}

#Print in console the public IP assigned to the instance
output "server_public_ip" {
    value = aws_eip.elastic-ip-1.public_ip
}

#9 - Create Ubuntu server and install/enable Apache

resource "aws_instance" "server" {

    ami = "ami-085925f297f89fce1"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"


    network_interface {

        device_index = 0 #First network instance of the device
        network_interface_id = aws_network_interface.net-interface-1.id

    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo systemctl enable apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF

    tags = {
        Name = "Ubuntu-web-server"
    }
}

#resource "<provider>_<resourcetype>" "name" {
#   config options...
#   key = "option"
#   key2 = "option2"
#}