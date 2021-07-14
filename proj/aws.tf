provider "aws" {
    region = "us-east-2"
}

resource "tls_private_key" "kk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "awskeys"
  public_key = "${tls_private_key.kk.public_key_openssh}"
}

resource "aws_instance" "web"{   
   
    ami =                    "ami-00399ec92321828f5"
    instance_type =          "t2.micro"
    key_name      = "${aws_key_pair.generated_key.key_name}"
    vpc_security_group_ids = [aws_security_group.web_sec.id]
    provisioner "local-exec" {
    command = "echo '${tls_private_key.kk.private_key_pem}' > ./myKey.pem; chmod 600 ./myKey.pem "
  }
    tags = {
    Role= "web"
    Env = "dev"
    }

 provisioner "remote-exec" {
    inline = ["echo asd"]

    connection {
      host = "${self.public_ip}"
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.kk.private_key_pem}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ./myKey.pem create.yml"
  }


}

resource "aws_security_group" "web_sec" {
  name        = "web_sec"
  
  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }  
}

