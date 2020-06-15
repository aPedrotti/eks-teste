#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS Services
#  * EC2 Security Group to allow networking traffic with eks cluster
#  * EKS Cluster
#  * IAM Role
#
resource "aws_iam_role" "desafio-node" {
  name = "eks-desafio-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "desafio-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.desafio-node.name
}
resource "aws_iam_role_policy_attachment" "desafio-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.desafio-node.name
}
resource "aws_iam_role_policy_attachment" "desafio-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.desafio-node.name
}
resource "aws_iam_instance_profile" "desafio-node" {
  name = "eks-desafio"
  role = aws_iam_role.desafio-node.name
}

#  * EC2 Security Group
resource "aws_security_group" "desafio-node" {
  name        = "eks-desafio-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.desafio.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name"                                      = "eks-desafio-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}
resource "aws_security_group_rule" "desafio-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.desafio-node.id
  source_security_group_id = aws_security_group.desafio-node.id
  to_port                  = 65535
  type                     = "ingress"
}
resource "aws_security_group_rule" "desafio-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.desafio-node.id
  source_security_group_id = aws_security_group.desafio-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

#  * EKS Workers
data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.desafio.version}-v*"]
  }
  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# https://aamzon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml

#locals {
#  desafio-node-userdata = <<USERDATA
##!/bin/bash -xe
#
#CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
#CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
#mkdir -p $CA_CERTIFICATE_DIRECTORY
#
#echo "${aws_eks_cluster.desafio.certificate_authority[0].data}" | base64 -d > CA_CERTIFICATE_FILE_PATH
#INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
#sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.desafio.endpoint},g /var/lib/kubelet/kubeconfig
#sed -i s,CLUSTER_NAME,${var.cluster-name}g /var/lib/kubelet/kubeconfig
#sed -i s,REGION,${data.aws_region.current.name},g /etc/systemd/system/kubelet.service
#sed -i s,MAX_PODS,20,G /etc/systemd/system/kubelet.service
#sed -i s,MASTR_ENDPOINT,${aws_eks_cluster.desafio.endpoint},g /etc/systemd/system/kubelet.service
#sed -i s,INTERNAL_IP,$INTERNAL_IP,/etc/systemd/system/kubelet.service
#DNS_CLUSTER_IP=10.100.0.10
#if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
#sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
#sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
#sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g /etc/systemd/system/kubelet.service
#systemctl daemon-reload
#systemctl restart kubelet
#USERDATA
#}
locals {
  desafio-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.desafio.endpoint}' --b64-cluster-ca '${aws_eks_cluster.desafio.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "desafio" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.desafio-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "t2.large"
  name_prefix                 = "eks-desafio"
  security_groups             = ["${aws_security_group.desafio-node.id}"]
  user_data_base64            = "${base64encode(local.desafio-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "desafio" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.desafio.id}"
  max_size             = 2
  min_size             = 1
  name                 = "eks-desafio"
  vpc_zone_identifier  = "${aws_vpc.desafio.*.id}"

  tag {
    key                 = "Name"
    value               = "eks-desafio"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}