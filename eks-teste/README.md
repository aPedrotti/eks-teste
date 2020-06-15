# Requirements
- aws access key (fill in variables.tf file if you don't have aws-cli configured)
- aws-iam-authenticator
- kubectl

## Download kubectl
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin
```

## Download the aws-iam-authenticator
```
wget https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.3.0/heptio-authenticator-aws_0.3.0_linux_amd64
chmod +x heptio-authenticator-aws_0.3.0_linux_amd64
sudo mv heptio-authenticator-aws_0.3.0_linux_amd64 /usr/local/bin/heptio-authenticator-aws
```


## Terraform apply
```
terraform init
terraform apply
```

## Configure kubectl
```
terraform output kubeconfig > kubeconfig
```
#Confirm with
```
kubectl config view
```
```
aws eks --region <region> update-kubeconfig --name desafio-eks
```

## Configure config-map-auth-aws
```
terraform output config-map-aws-auth > config-map-aws-auth.yaml
kubectl apply -f config-map-aws-auth.yaml
```

## See nodes coming up
```
kubectl get nodes -w
```

## Deploy application 
```
cd app && terraform init
terraform plan
terraform apply
```

## Destroy
Make sure all the resources created by Kubernetes are removed (LoadBalancers, Security groups), and issue:
```
terraform destroy
```

