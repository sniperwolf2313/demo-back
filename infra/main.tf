terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" { region = var.aws_region }

resource "random_id" "suffix" { byte_length = 3 }

# Bucket S3 para almacenar versiones (zip) de EB
resource "aws_s3_bucket" "eb_versions" {
  bucket        = "${var.project}-eb-versions-${random_id.suffix.hex}"
  force_destroy = true
}

# Roles mínimos que EB necesita
# Rol de servicio de EB (Enhanced Health / eventos)
data "aws_iam_policy_document" "eb_service_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "eb_service" {
  name               = "${var.project}-eb-service-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.eb_service_trust.json
}
resource "aws_iam_role_policy_attachment" "eb_service_health" {
  role       = aws_iam_role.eb_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# Rol para la instancia EC2 del environment
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "eb_ec2_role" {
  name               = "${var.project}-eb-ec2-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}
resource "aws_iam_role_policy_attachment" "web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}
resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "${var.project}-eb-profile-${random_id.suffix.hex}"
  role = aws_iam_role.eb_ec2_role.name
}

# Aplicación EB
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "Java Spring Boot (Gradle) demo"
}

# Plataforma Java 17 en Amazon Linux 2 (obtenemos la más reciente que matchea)
data "aws_elastic_beanstalk_solution_stack" "java17" {
  name_regex  = "64bit Amazon Linux 2.*Corretto 17"
  most_recent = true
}

# Environment SingleInstance (sin balanceador) + SERVER_PORT=5000 para Spring Boot
resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.java17.name

  # Tipo de entorno
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
  # Perfil de instancia
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }
  # Rol de servicio
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service.arn
  }
  # Puerto destino de la app (Spring leerá SERVER_PORT → server.port)
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"
    value     = "5000"
  }
}
