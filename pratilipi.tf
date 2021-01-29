provider "aws" {
  version = "~> 2.0"
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}
resource "aws_vpc" "pratilipi-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
    Name = "pratilipi-vpc"
  }
}

resource "aws_subnet" "prod-subnet-public-1" {
    vpc_id = "${aws_vpc.pratilipi-vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
    tags = {
        Name = "prod-subnet-public-1"
    }
}


resource "aws_internet_gateway" "prod-igw" {
    vpc_id = "${aws_vpc.pratilipi-vpc.id}"
    tags = {
        Name = "prod-igw"
    }
}

resource "aws_route_table" "prod-public-crt" {
    vpc_id = "${aws_vpc.pratilipi-vpc.id}"

    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0"
        //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.prod-igw.id}"
    }

    tags = {
        Name = "prod-public-crt"
    }
}

resource "aws_security_group" "Egnyte" {
    vpc_id = "${aws_vpc.Egnyte-vpc.id}"
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "Egnyte"
    }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    route_table_id = "${aws_route_table.prod-public-crt.id}"
}

resource "aws_instance" "Egnyte" {
    count= "5"
    ami = "ami-00008506813cea27a"
    instance_type = "t2.micro"
    key_name = "Egnyte"
    tags = {
     Name = "Egnyte"
    }
    # VPC
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    # Security Group
    vpc_security_group_ids = ["${aws_security_group.Egnyte.id}"]
    provisioner "file" {
    source="script.sh"
    destination="/tmp/script.sh"
    }
    provisioner "remote-exec" {
    inline=[
    "chmod +x /tmp/script.sh",
    "sudo /tmp/script.sh"
    ]
    }
    connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("/home/ec2-user/Egnyte.pem")
    host = aws_instance.Egnyte.public_ip
  }
}
