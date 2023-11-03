provider "aws" {
  region = local.region
}
data "aws_availability_zones" "available" {}

locals {
  region = "us-east-1"
  cluster_name = "my-eks"

  vpc_name = "my-vpc"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  #   - Cluster should use latest available Kubernetes version (supported by AWS in EKS service)  
  # not mentioning cluster version should create the latest version 
  cluster_name                   = local.cluster_name

#   - It should have only private API server endpoint access  
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  enable_irsa = true

  cluster_additional_security_group_ids = [aws_security_group.additional_sg_1.id]

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    vpc-cni = {
      most_recent = true
    }
  }
  #   - It should have one node group with minumum 1 and maximum 5 ondemand nodes of any EC2 type  
  eks_managed_node_groups = {
    general = {
      desired_size = 1
      min_size     = 1
      max_size     = 5
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }
  }

}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name

  cidr = local.vpc_cidr
  azs  = local.azs

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.3.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

#   - It should have one cluster and one additional security group 
resource "aws_security_group" "additional_sg_1" {
  name_prefix = "additional-sg-1-"
  vpc_id      =  module.vpc.vpc_id

}