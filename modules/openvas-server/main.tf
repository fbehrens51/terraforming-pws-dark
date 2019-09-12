data "aws_route_table" "route_table" {
  route_table_id = "${var.route_table_id}"
}

data "aws_vpc" "vpc" {
  id = "${data.aws_route_table.route_table.vpc_id}"
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${data.aws_route_table.route_table.id}"
}

resource "tls_private_key" "openvas" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_subnet" "subnet" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  # 10.0.200.32/28
  cidr_block              = "${cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, 3201)}"
  map_public_ip_on_launch = true

  tags {
    Name        = "openvas server subnet"
    Description = "This subnet is meant to have internet access"
  }
}

resource "aws_security_group" "openvas_security_group" {
  vpc_id      = "${aws_subnet.subnet.vpc_id}"
  name        = "${var.vm_name} Security Group"
  description = "${var.vm_name} Security Group"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  // allow all egress traffic rule
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags {
    Name = "vm_security_group"
  }
}

resource "aws_instance" "openvas" {
  availability_zone      = "${aws_subnet.subnet.availability_zone}"
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${aws_key_pair.openvas.key_name}"
  vpc_security_group_ids = ["${aws_security_group.openvas_security_group.id}"]
  subnet_id              = "${aws_subnet.subnet.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  provisioner "file" {
    source      = "${path.module}/conf"
    destination = "/tmp"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.openvas.private_key_pem}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "bash -ex /tmp/conf/configure.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.openvas.private_key_pem}"
    }
  }

  tags = "${map("Name", "${var.vm_name}")}"
}

resource "aws_key_pair" "openvas" {
  key_name   = "${var.env_name} ${var.vm_name} Key Pair"
  public_key = "${tls_private_key.openvas.public_key_openssh}"
}

resource "aws_elb_attachment" "openvas_elb_attachement" {
  elb      = "${var.openvas_elb_name}"
  instance = "${aws_instance.openvas.id}"
}
