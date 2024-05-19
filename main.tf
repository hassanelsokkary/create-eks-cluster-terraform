# Creating VPC and Subnets, IGW, and NAT
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc"
  }
}
# Creating Role ARN for EKS

resource "aws_iam_role" "eks-role" {
  name = "eks-cluster-role"
  tags = {
    tag-key = "eks-cluster-group-5-role"
  }

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "eks.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

# Attach Policy to EKS

resource "aws_iam_role_policy_attachment" "eks-role-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Creating EKS cluser
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  iam_role_arn = aws_iam_role.eks-role.arn
  depends_on = [aws_iam_role_policy_attachment.eks-role-AmazonEKSClusterPolicy]
  
  cluster_name    = "eks-cluster"
  cluster_version = "1.29"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  access_entries = {
    group5 = {
        kubernetes_group  = []
        principal_arn     = "###### USER ARN to authorize in Cluster#########"

        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              namespaces = []
              type       = "cluster"
            }
          }
        }
    }
  }

  eks_managed_node_group_defaults = {
    disk_size = 10
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.micro"]
  }

  eks_managed_node_groups = {
    general = {
      use_custom_launch_template = false
      min_size     = 1
      desired_size = 2
      max_size     = 3
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote-access.id]
      }
      labels = {
        role = "worker"
      }
    }

    
  }

  tags = {
    Environment = "eks-cluster"
  }
}

# Create Key pair to use with SSH
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name    = "key-eks"
  create_private_key = true

  tags = {
    Name = "key-eks"
  }
}

# Create Security group to enable port 22 for SSH
resource "aws_security_group" "remote-access" {
  name = "eks-node-sec-group"
  description = "Allow remote SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "eks-node-sec-group"
  }
}