
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  cluster_name                   = local.cluster_name

  # only private API server endpoint access  
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  enable_irsa = true
  
  # one cluster and one additional security group 
  create_cluster_security_group = true
  cluster_additional_security_group_ids = [aws_security_group.additional_sg_1.id]
  
  # node group with minumum 1 and maximum 5 ondemand nodes of any EC2 type  
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

