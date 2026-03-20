terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment and configure after creating S3 bucket + DynamoDB table for remote state
  # backend "s3" {
  #   bucket         = "claude-automation-tfstate"
  #   key            = "3tier/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "claude-automation-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ─── Networking ────────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  app_subnet_cidrs     = var.app_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ─── Web Tier ──────────────────────────────────────────────────────────────────
module "web" {
  source = "./modules/web"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  web_sg_id           = module.networking.web_sg_id
  alb_sg_id           = module.networking.alb_sg_id
  instance_type       = var.web_instance_type
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_desired_capacity
  ami_id              = var.ami_id
  key_name            = var.key_name
  certificate_arn     = var.certificate_arn
  app_alb_dns_name    = module.app.alb_dns_name
}

# ─── App Tier ──────────────────────────────────────────────────────────────────
module "app" {
  source = "./modules/app"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  app_subnet_ids     = module.networking.app_subnet_ids
  app_sg_id          = module.networking.app_sg_id
  app_alb_sg_id      = module.networking.app_alb_sg_id
  instance_type      = var.app_instance_type
  min_size           = var.app_min_size
  max_size           = var.app_max_size
  desired_capacity   = var.app_desired_capacity
  ami_id             = var.ami_id
  key_name           = var.key_name
  db_endpoint        = module.database.db_endpoint
  db_name            = var.db_name
  db_secret_arn      = module.database.db_secret_arn
}

# ─── Database Tier ─────────────────────────────────────────────────────────────
module "database" {
  source = "./modules/database"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  db_subnet_ids     = module.networking.db_subnet_ids
  db_sg_id          = module.networking.db_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_instance_class = var.db_instance_class
  db_engine         = var.db_engine
  db_engine_version = var.db_engine_version
  multi_az          = var.db_multi_az
  allocated_storage = var.db_allocated_storage
}
