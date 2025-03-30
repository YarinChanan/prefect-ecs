module "vpc" {
  source  = "terraform-aws-modules/vpc/aws" #module will be downloaded from the Terraform Registry.
  version = "5.1.1"

  name = "${var.cluster_name}-vpc"
  cidr = "10.2.0.0/16" #defines the IP address range that will be used within the VPC
  azs  = ["eu-central-1a", "eu-central-1b"]

  public_subnets  = ["10.2.64.0/24", "10.2.65.0/24"]   # Two different CIDRs for public subnets
  private_subnets = ["10.2.128.0/24", "10.2.129.0/24"] # Two different CIDRs for private subnets

  enable_nat_gateway      = true
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true
}


output "vpc_id" {
  value = module.vpc.vpc_id
}


