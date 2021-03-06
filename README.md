
# Prerequisites
- Terraform >=v0.12
https://www.terraform.io/downloads.html
- AWS CLI
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
aws configure 
- AWS IAM Authenticator
https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
- kubectl
https://kubernetes.io/docs/tasks/tools/install-kubectl/
- wget (required for the eks module)
https://www.gnu.org/software/wget/


1. Fulfil variables.tf file to add your credentials to AWS and change defined names as desired.

# Check if all data have being filled
$ terraform init 
$ terraform plan
# Roll it up - It should take about 10 min to be done
$ terraform apply
# Configure cluster's credentials 
$ terraform output kubeconfig > kubeconfig
# Confirm by
$ kubectl config view
# At this point you won't see any nodes or pods. To get that, configure configmap of authentication
$ terraform output config-map-aws-auth > aws-auth.yaml && kubectl apply -f aws-auth.yaml
# Check until nodes are ready
$ kubectl get nodes -w


Results:
EKS Cluster Creating Steps
- Create ServiceRole - Give the master control-place permission to create cluster on behalf of you
- Create VPC - Create subnets to allow a HA network for your worker nodes exposing them via gateway
- Create Cluster - EKS with a HA ETCD and Master Control-Plane
- Provision Worker Nodes - Provision EC2 instances with a configuration file allows them communicate with EKS
- Apply AWS-Auth - Allow your instances to connect with EKS
- Apply app/ data;
