variable "aws_key_name" {}
variable "ami" {}
variable "instance_type" {}
variable "public_ip" {}
variable "private_key" {}

module "server" {
    source        = "./server"
    ami           = "${var.ami}"
    aws_key_name  = "${var.aws_key_name}"
    instance_type = "${var.instance_type}"
    public_ip     = "${var.public_ip}"
    private_key   = "${var.private_key}"
}