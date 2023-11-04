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
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
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
  
  #   - It should have one cluster and one additional security group 
  create_cluster_security_group = true
  cluster_additional_security_group_ids = [aws_security_group.additional_sg_1.id]
  
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

resource "aws_security_group" "additional_sg_1" {
  name_prefix = "additional-sg-1-"
  vpc_id      =  module.vpc.vpc_id
  description = "Allow TLS inbound traffic"
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

