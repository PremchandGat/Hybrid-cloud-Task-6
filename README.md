# Hybrid-cloud-Task-6
Deploy the Wordpress application on Kubernetes and AWS using terraform including the following steps;

1.  Write an Infrastructure as code using terraform, which automatically deploy the Wordpress application
2.  On AWS, use RDS service for the relational database for Wordpress application.
3. Deploy the Wordpress as a container either on top of Minikube or EKS or Fargate service on AWS
4. The Wordpress application should be accessible from the public world if deployed on AWS or through workstation if deployed on Minikube.


# How to use code
<pre>
1. First download terraform code
2. Do some changes in code according to requirement
   change aws profile name 
3. Run command <b>terraform init</b>
4. Run command <b>terraform apply</b> </pre>

# Create  terraform code
<pre>
provider "aws" {
  region     = "ap-south-1"
  profile    = "prem" <b># change profile name</b>
}
</pre>
# Create a security group for mysql data base this allows port no 3306 
<pre>
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
</pre>
# create a aws data base instance
<pre>
resource "aws_db_instance" "default" {
  allocated_storage    = 20                          <b># database storage size </b>
  storage_type         = "gp2"                       <b># database storage type </b>
  engine               = "mysql"                     <b># database type or database engine name </b>
  engine_version       = "5.7"                       <b># database version</b>
  instance_class       = "db.t2.micro"               <b># instance type in which database run</b>
  name                 = "mydb"                      <b># database name</b>
  username             = "prem"                      <b># database username</b>
  password             = "premchand"                 <b># database password</b> 
  parameter_group_name = "default.mysql5.7"          
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.allow_mysql.id,]
}
</pre>
# show public ip of database 
<pre>
output "ipaddresse" {
  value = aws_db_instance.default.endpoint
}
</pre>

# create code to launch wordpress on minikube
<pre>
provider "kubernetes" {
  config_context_cluster = "minikube"
}
</pre>
# create a deployment of wordpress image
<pre>
resource "kubernetes_deployment" "launch_wordpress" {
    metadata {
    name = "wordpress-terraform"  <b># deployment name</b>
    labels = {                    <b># deployment label</b>
      app = "wordpress"
      prod = "INDIA"
       }
    }
    spec {
    replicas = 1                 <b># set to 1 replica which means one wordpress container always run</b>  
    selector {
      match_labels = {
      app = "wordpress"
      prod = "INDIA"
      }
    }
    strategy {
      type = "Recreate"        <b># strategy type</b>
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
          image = "wordpress:php7.2"           <b># docker container name of wordpress image</b>
          name  = "wordpress"
          <b># these are wordpress container image enviromental variables which are required</b>
          env  {
              name  = "WORDPRESS_DB_HOST"                    <b># wordpress database host name or url </b>
              value = "${aws_db_instance.default.endpoint}:3306"
            }
          env {
              name  = "WORDPRESS_DB_USER"             <b># database user name </b>
              value = "prem"
            }          
            env {
              name  = "WORDPRESS_DB_PASSWORD"          <b># database password</b>
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
</pre>
# create service for wordpress deployment to expose port no 80 
<pre>
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
      port        = 3000          <b># we can access wordpress through port no 3000 of minikube ip </b>
      protocol    = "TCP"
      target_port = 80            <b># wordpress port no to be exposed to public</b>
    }   
    type = "LoadBalancer"          <b># service type</b>
  }
}
</pre>
