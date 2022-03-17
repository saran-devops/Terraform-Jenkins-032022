provider "aws" {
  region  = "us-east-2"
}

resource "aws_default_vpc" "default" {
}


resource "aws_s3_bucket" "my-s3-bucket" {
  bucket_prefix = var.bucket_prefix
  tags = {
    Name = "AWS-S3-Bucket"
  }
}

resource "aws_s3_bucket_acl" "my-s3-bucket-acl" {
  bucket = aws_s3_bucket.my-s3-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_s3_bucket" {
  bucket = aws_s3_bucket.my-s3-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "Allow ssh and standard http/https ports inbound and everything outbound"
  vpc_id      = aws_default_vpc.default.id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.large"
  vpc_security_group_ids = [aws_security_group.web_traffic.id]
  subnet_id              = tolist(data.aws_subnets.default_subnets.ids)[0]
  key_name               = "ubuntukey"

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt-get upgrade",
      "sudo apt-get update",
      "sudo apt update",
      "sudo apt install -y openjdk-11-jdk",
      "sudo apt update",
      "sudo apt install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo sh -c \"iptables-save > /etc/iptables.rules\"",
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
      "sudo apt-get -y install iptables-persistent",
      "sudo ufw allow 8080",
      "java --version",
      "python3 --version"
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/ubuntukey.pem")
  }

  tags = {
    "Name"      = "Jenkins_Server"
    "Terraform" = "true"
  }
}
