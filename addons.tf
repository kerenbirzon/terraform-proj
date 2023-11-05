
module "addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn  

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns    = {
      prepare = true
      most_recent = true
    }
    kube-proxy = {}
    vpc-cni = {
      preserve    = true
      most_recent = true 

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
  }
  
  enable_cluster_autoscaler = true
  enable_metrics_server = true
}