provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "example" {
  cidr_block = "${var.vpc_cidr_block}"

  tags {
    Name = "${var.vpc_name}"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = "${aws_vpc.example.id}"
}

resource "aws_subnet" "example-public" {
  vpc_id                  = "${aws_vpc.example.id}"
  cidr_block              = "${var.public_subnet_cidr_block}"
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

resource "aws_default_route_table" "example_private_rt" {
  default_route_table_id = "${aws_vpc.example.default_route_table_id}"

  tags {
    Name = "example-private-rt"
  }
}

resource "aws_route_table_association" "example_public_assoc" {
  subnet_id      = "${aws_subnet.example-public.id}"
  route_table_id = "${aws_route_table.example-public.id}"
}

resource "aws_subnet" "example-private-sg" {
  vpc_id                  = "${aws_vpc.example.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  

  tags {
    Name = "example-private-sg"
  }
}

resource "aws_security_group" "example-public-sg" {
  name        = "example-public-sg"
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
  vpc_security_group_ids = ["${aws_security_group.example-public-sg.id}"]
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

output "public_ip" {
  value = "${aws_instance.http.public_ip}"
}
