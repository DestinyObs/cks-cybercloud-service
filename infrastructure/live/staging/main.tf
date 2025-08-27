locals {
  common_tags = {
    Project     = "naas-prod"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Network Module
module "network" {
  source = "../../modules/network"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name

  tags = local.common_tags
}

# Security Group Module
module "security_group" {
  source = "../../modules/security-group"
  
  vpc_id       = module.network.vpc_id
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
}

# Key Pair Module
module "key_pair" {
  source = "../../modules/key-pair"
  
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
}

# EC2 Compute Module
module "compute_ec2" {
  source = "../../modules/compute-ec2"
  
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  security_group_ids    = [module.security_group.kubernetes_sg_id]
  instance_profile_name = module.iam.instance_profile_name
  key_pair_name         = module.key_pair.key_name
  
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type
  master_count         = var.master_count
  worker_count         = var.worker_count
  
  environment  = var.environment
  project_name = var.project_name
  
  tags = local.common_tags
}

# Budgets Module
module "budgets" {
  source = "../../modules/budgets"
  
  environment     = var.environment
  project_name    = var.project_name
  budget_limit    = var.budget_limit
  alert_threshold = var.alert_threshold
  alert_emails    = var.alert_emails
  
  tags = local.common_tags
}