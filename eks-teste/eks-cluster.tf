#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS Services
#  * EC2 Security Group to allow networking traffic with eks cluster
#  * EKS Cluster
#

resource "aws_iam_role" "desafio-cluster" {
  name = "eks-desafio-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "desafio-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.desafio-cluster.name
}

resource "aws_iam_role_policy_attachment" "desafio-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.desafio-cluster.name
}

# If no loadbalancer was ever created in this region, then this following role is necessary
resource "aws_iam_role_policy" "desafio-cluster-service-linked-role" {
  name = "service-linked-role"
  role = aws_iam_role.desafio-cluster.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_security_group" "desafio-cluster" {
  name        = "eks-desafio-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.desafio.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-desafio"
  }
}

resource "aws_security_group_rule" "desafio-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.desafio-cluster.id
  source_security_group_id = aws_security_group.desafio-node.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "desafio-cluster-ingress-workstation-https" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.desafio-cluster.id
  to_port           = 443
  type              = "ingress"
}


resource "aws_eks_cluster" "desafio" {
  name     = var.cluster-name
  role_arn = aws_iam_role.desafio-cluster.arn

  vpc_config {
    security_group_ids = ["${aws_security_group.desafio-cluster.id}"]
    subnet_ids         = "${aws_subnet.desafio.*.id}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.desafio-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.desafio-cluster-AmazonEKSServicePolicy,
  ]
}

