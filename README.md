# Terragrunt Example

## Initialize your workstation

```
export BUCKET="devops-workshop-$(uuidgen | tr "[:upper:]" "[:lower:]")"
export ACCOUNT_ID=""
aws s3api create-bucket --bucket "${BUCKET}"
```

## Provision a VPC

```
terragrunt init
cd infra/vpc
terragrunt apply
```

## Provision an EKS

```
terragrunt init
cd infra/eks
terragrunt apply
```

## Provision an EFS

```
terragrunt init
cd infra/efs
terragrunt apply
```

## Provision a nodeGroup

```
terragrunt init
cd infra/nodeGroups/managed-node-group/internal-services
terragrunt apply
```

## Provision a metrics-server

```
terragrunt init
cd infra/metrics-server
terragrunt apply
```

## Provision an ingress-nginx

```
terragrunt init
cd services/ingress-nginx
terragrunt apply
```


Add the following to your /etc/hosts: 

```
echo "$(dig +short <NLB DNS>) anthonycornell.com."
```

navigate:
https://anthonycornell.com/apple
https://anthonycornell.com/banana

```
curl  http://anthonycornell.com/apple
curl  http://anthonycornell.com/banana
```
