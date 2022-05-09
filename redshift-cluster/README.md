# Redshift cluster

The terraform code of this folder provisions a Redshift cluster. It requires the provisioning of:

- a VPC to isolate the redshift cluster
- a subnet within the VPC
- a subnet group for the redshift cluster
- an internet gateway to access the cluster from outside the VPC
- the redshift cluster

# Set-up instructions

To initialize the terraform project with S3 backend:

```
export ENV="dev"
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
export PROJECT_NAME="gbto"
export TERRAFORM_BUCKET_NAME="${PROJECT_NAME}-tf-states-${ENV}"

terraform init \
        -backend-config="bucket=${TERRAFORM_BUCKET_NAME}" \
        -backend-config="key=${PROJECT_NAME}-redshift-cluster-${ENV}.tfstate" \
        -backend-config="region=$AWS_REGION"
```

To create the deployment plan and apply it:

```
# format the terraform code
terraform fmt

# plan the deployment of resources
terraform plan

# deploy the resources to AWS
terraform apply

# destroy the existing AWS resources
terraform destroy
```
