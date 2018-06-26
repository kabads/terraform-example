provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "example" {
  cidr_block = "198.18.0.0/16"

  tags {
    Name = "example-vpc"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = "${aws_vpc.example.id}"
}

resource "aws_subnet" "example-public" {
  vpc_id                  = "${aws_vpc.example.id}"
  cidr_block              = "198.18.1.0/24"
  map_public_ip_on_launch = "true"
}

resource "aws_route_table" "example-public" {
  vpc_id = "${aws_vpc.example.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.example.id}"
  }

  tags {
    Name = "example-public"
  }
}

resource "aws_route_table_association" "example_public_assoc" {
  subnet_id      = "${aws_subnet.example-public.id}"
  route_table_id = "${aws_route_table.example-public.id}"
}

resource "aws_security_group" "example-sg" {
  name        = "example-sg"
  description = "used for port 80 traffic"
  vpc_id      = "${aws_vpc.example.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "http" {
  ami                    = "ami-922914f7"
  instance_type          = "t2.micro"
  key_name               = "${var.keyname}"
  vpc_security_group_ids = ["${aws_security_group.example-sg.id}"]
  subnet_id              = "${aws_subnet.example-public.id}"

  tags {
    Name = "http-example"
  }

  user_data = <<EOF
               #!/bin/bash
               yum update -y 
               yum upgrade -y 
               yum install httpd24 -y
               service httpd start
               echo "Hello Adam from the terraform script" > /var/www/html/index.html
               chown apache.apache /var/www/html/index.html
               chmod 755 /var/www/html/index.html
               EOF
}
