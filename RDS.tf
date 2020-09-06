provider "aws" {
  region     = "ap-south-1"
  profile    = "prem"
}
resource "aws_security_group" "allow_mysql" {
  name        = "security_created_by_terraform_for_mysql"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-73f5ea1b"

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mysql"
  }
}
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "prem"
  password             = "premchand"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.allow_mysql.id,]
}
output "ipaddresse" {
  value = aws_db_instance.default.endpoint
}
provider "kubernetes" {
  config_context_cluster = "minikube"
}
resource "kubernetes_deployment" "launch_wordpress" {
    metadata {
    name = "wordpress-terraform"
    labels = {
      app = "wordpress"
      prod = "INDIA"
       }
    }
    spec {
    replicas = 1
    selector {
      match_labels = {
      app = "wordpress"
      prod = "INDIA"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
    metadata {
        labels = {
          app = "wordpress",
          prod = "INDIA"
        }
      }
      spec {
        container {
          image = "wordpress:php7.2"
          name  = "grafana"
          env  {
              name  = "WORDPRESS_DB_HOST"
              value = "${aws_db_instance.default.endpoint}:3306"
            }
          env {
              name  = "WORDPRESS_DB_USER"
              value = "prem"
            }          
            env {
              name  = "WORDPRESS_DB_PASSWORD"
              value = "premchand"
            }
          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          } 
        }
      }
    }
  }
}
resource "kubernetes_service" "wordpress-port" {
  metadata {
    name      = "wordpress-port"
  }
  spec {
    selector = {
      app = "wordpress"
      prod = "INDIA"     
    }
    port {
      name        = "http"
      port        = 3000
      protocol    = "TCP"
      target_port = 80
    }   
    type = "LoadBalancer"
  }
}
