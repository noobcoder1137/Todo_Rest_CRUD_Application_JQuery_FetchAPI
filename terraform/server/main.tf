variable "ami" {}
variable "aws_key_name" {}
variable "instance_type" {}
variable "public_ip" {}
variable "private_key" {}


resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "subnet1"
  }
}
resource "aws_security_group" "ghost_web_sg" {
  name        = "ghost_web_sg"
  description = "Allow incoming HTTP/HTTPS connections & SSH access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

//   ingress {
//     from_port   = -1
//     to_port     = -1
//     protocol    = "icmp"
//     cidr_blocks = ["0.0.0.0/0"]
//   }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "Web Server (ghost) SG"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "VPC IGW"
  }
}

resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "Public Subnet RT"
  }
}
resource "aws_route_table_association" "web-public-rt" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

resource "aws_instance" "web" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${aws_subnet.subnet1.id}"
  key_name      = "${var.aws_key_name}"
  tags = {
    "Name" = "Rob ghost EC2"
  }
  vpc_security_group_ids      = ["${aws_security_group.ghost_web_sg.id}"]
  associate_public_ip_address = true
  source_dest_check           = false
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
    private_key = "${file("${var.private_key}")}"
    host        = "${self.public_ip}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = "${aws_instance.web.id}"
  public_ip = "${var.public_ip}"
}

// resource "aws_eip" "eip" {
//   vpc = true
// }