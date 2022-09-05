# main.tf

# Create the VPC
resource "aws_vpc" "Main" {
    cidr_block  = var.main_vpc_cidr
    instance_tenancy = "default"
    tags = {
        name = "Terraform_VPC"
  }  
}

# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "IGW" {
    vpc_id  =   aws_vpc.Main.id
      tags = {
        name = "Terraform_IGW"
  } 
}

# Create a Public Subnet
resource "aws_subnet" "publicsubnets" {
    vpc_id  =   aws_vpc.Main.id
    cidr_block = "${var.public_subnets}"
      tags = {
        name = "Terraform_Public_Subnet"
  } 
}

# Create Private Subnets
resource "aws_subnet" "privatesubnets" {
    vpc_id  = aws_vpc.Main.id
    cidr_block = "${var.private_subnets}"
      tags = {
        name = "Terraform_Private_Subnet"
  } 
}

# Route table for Public Subnets
resource "aws_route_table" "PublicRT" {
    vpc_id  =  aws_vpc.Main.id
        route {
            cidr_block  =  "0.0.0.0/0"
            gateway_id = aws_internet_gateway.IGW.id
        }
      tags = {
        name = "Terraform_PublicRT"
    } 
}

# Route table for Private Subnet's
#  resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
#    vpc_id = aws_vpc.Main.id
#    route {
#    cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
#    nat_gateway_id = aws_nat_gateway.NATgw.id
#    }
#      tags = {
#         name = "Terraform_PrivateRT"
#   } 
#  }

 # Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }

 # Route table Association with Private Subnet's
#  resource "aws_route_table_association" "PrivateRTassociation" {
#     subnet_id = aws_subnet.privatesubnets.id
#     route_table_id = aws_route_table.PrivateRT.id
#  }

#   resource "aws_eip" "nateIP" {
#    vpc   = true
#  }

 #Creating the NAT Gateway using subnet_id and allocation_id
#  resource "aws_nat_gateway" "NATgw" {
#    allocation_id = aws_eip.nateIP.id
#    subnet_id = aws_subnet.publicsubnets.id
#      tags = {
#         name = "Terraform_NatGW"
#     } 
#  }

 resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.Main.id

  ingress {
    description      = "SSH to VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["72.89.195.168/32"]  # Enter your IP Address
    # ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "Web Access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
    # ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_SSH"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "Terraform-lab-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBJanmS3h6AtUXRrXLAkuX2Onet8WUUQ/un1Y7UbCDnn7UuuoIXHjTwpTwmBDxmpWgJKl1V/g6TBUNt97E3GJLmeZ00M522FVHynBtSVLz7z6kYXhap4ZQFAVrzxFUMK7jKBaCLlnMsqJSQp9NZkMSsX3D2J+vLQ/ii16poFzVUXGl8mD0GF/BR/6h1eDL2XNwj2A40o6k03EHRqCkuq4UGsrRmWUfc11JcHBSa4b4tSzs54mgMU+8tIPCbMQpnap26bnFYOkmBIJMt1gcXJs+qKRhQG011w2cHr2Va1t5FoI85BhrN16KKSpnFqRH7Z8/0S3NtubXgk1tuSG11D1NiMwm3mwuDyMJ8plAwfHJcQ3vMYD8r4WK899/xDuLfP8ih2G3zDstmfNRXOw2hWiIcnhpiu5pv/xAalAeAMkLUwgcikzU1XSVDVfe6XSngL8yUUFj3ZOGMqsOJBTbMywX8TLJgFyvP1IdSLWyIJmZ1ARP3dEKT2LmNBr7ZWrkJGr5Q87xhZHtb0+Su0W3AfNGAykJrfPSYgqT3FzVeJ0G+nKy5rI7RstD4L4L9Yt/sZxTh9TWXsIbL58qtmwdRBAiDAecUBYEyLnSkPvEjAODuhYKumDGYmwX5wfIaM5i9PDQ+MS5HjxjqqRJS+5uGnJOQgyR2KVfJBoiWiYiH/mRhQ== kwab_ubuntu@Kwab-IdeaPad" # Enter your public SSH key
}

 resource "aws_instance" "web" {
  for_each = toset(["Webserver1", "Webserver2", "Loadbalancer"])

  # name = "${each.key}"
  subnet_id = aws_subnet.publicsubnets.id
  ami           = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  tags = {
    Name = "${each.key}"
  }
}

output "webserver1_public_ip" {
  description = "Public IP address of the webserver1 EC2 instance"
  value       = aws_instance.web["Webserver1"].public_ip
}

output "webserver2_public_ip" {
  description = "Public IP address of the webserver2 EC2 instance"
  value       = aws_instance.web["Webserver2"].public_ip
}

output "loadbalancer_public_ip" {
  description = "Public IP address of the loadbalancer EC2 instance"
  value       = aws_instance.web["Loadbalancer"].public_ip
}

