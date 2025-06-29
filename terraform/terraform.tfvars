# terraform/terraform.tfvars
aws_region   = "us-west-2"  # Cambiar por tu región
environment  = "dev"
project_name = "craftista"

# Networking
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]

# EKS
cluster_name         = "craftista-cluster"
node_group_name      = "craftista-nodes"
node_instance_types  = ["t3.medium"]
node_desired_size    = 2
node_max_size        = 4
node_min_size        = 1