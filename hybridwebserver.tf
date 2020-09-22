#Hybrid Wordpress setup

provider "aws" {
  region                  = "ap-south-1"
  profile                 = "default"
}

provider "kubernetes" {}

resource "aws_db_instance" "default" {
  identifier           = "mysql-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mysqldb"
  username             = "admin"
  password             = "pass123word"
  parameter_group_name = "default.mysql5.7"
  final_snapshot_identifier = "mysql-db-snapshot"
  publicly_accessible  = true
}


resource "kubernetes_service" "lb" {
  metadata {
    name = "wordpress-lb"
  }
  spec {
    selector = {
      app = "wp"
    }
    port {
      port        = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_persistent_volume_claim" "volume" {
  metadata {
    name = "pvc"
  }
  spec {
    access_modes = [ "ReadWriteMany" ]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}


resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wp-deploy"
    labels = {
      app = "wp"
      country = "IN"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        country = "IN"
        app     = "wp"
      }
    }

    template {
      metadata {
        labels = {
          country = "IN"
          app     = "wp"
        }
      }

      spec {
        container {
          image = "wordpress"
          name  = "wordpress"
          env {
             name = "WORDPRESS_DB_HOST"  
             value = "${aws_db_instance.default.endpoint}"
          }
          env {
             name = "WORDPRESS_DB_USER"  
             value = "admin"
          }
          env {
             name = "WORDPRESS_DB_PASSWORD"  
             value = "pass123word"
          }
          env {
             name = "WORDPRESS_DB_NAME"  
             value = "mysqldb"
          } 
          volume_mount {
            name            =  "wpmount"
            mount_path      =  "/var/www/html"
          }
        }
        volume {
           name  =  "wpmount"
           persistent_volume_claim  {
             claim_name  =  "pvc"
           }
        }
      }
    }  
  }
}


output "Endpoint" {
  value = "${aws_db_instance.default.endpoint}"
}