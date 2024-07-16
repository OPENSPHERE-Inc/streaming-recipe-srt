terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "name" {
  description = "The name of the EC2 Instance"
  type = string
  default = "OBS Studio Server"
}

variable "key_name" {
  description = "The name of the EC2 Key Pair to allow SSH access to the instance"
  type = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type = string
}

variable "subnet_id" {
  description = "The ID of the Subnet"
  type = string
}

variable "iam_role_name" {
  description = "The name of the IAM Role"
  type = string
}

resource "aws_iam_instance_profile" "obs" {
  name = "obs_server_profile"
  role = var.iam_role_name
}

resource "aws_security_group" "obs_server" {
  name = "obs_security_group"
  description = "Allow inbound traffic from anywhere on port 3389,8843 and 20001-20010"
  vpc_id = var.vpc_id

  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "RDP(Remove later)"
  }
  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "udp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "NICE DCV"
  }
  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "NICE DCV"
  }
  ingress {
    from_port = 20001
    to_port = 20010
    protocol = "udp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SRT"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name = var.name
  }
}

resource "aws_network_interface" "obs_server" {
  subnet_id = var.subnet_id

  security_groups = [
    aws_security_group.obs_server.id,
  ]

  tags = {
    Name = var.name
  }
}

resource "aws_instance" "obs_server" {
  ami = "ami-0987eed561fe06332"
  instance_type = "g4ad.xlarge"
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.obs.name

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.obs_server.id
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }

  user_data = <<EOF
    <powershell>
      # 毎起動時にインスタンスストアをフォーマットして利用可能にします
      Get-Disk | `
        Where-Object -FilterScript {($_.FriendlyName -Eq "NVMe Amazon EC2 NVMe") `
        -And ($_.PartitionStyle -Eq "RAW")} | `
        Initialize-Disk -PartitionStyle GPT -PassThru -confirm:$false | `
        New-Partition -UseMaximumSize -AssignDriveLetter | `
        Format-Volume -NewFileSystemLabel "Instance Store" -FileSystem NTFS -Force -confirm:$false

      if (!(Test-Path "D:\OBSRecord")) {
        New-Item D:\OBSRecord -type Directory
      }
    </powershell>
    <persist>true</persist>
  EOF

  tags = {
    Name = var.name
  }
}

resource "aws_eip" "obs_server" {
  instance = aws_instance.obs_server.id

  tags = {
    Name = var.name
  }
}
