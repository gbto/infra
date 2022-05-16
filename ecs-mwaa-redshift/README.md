# Data platform engineering

The data engineering resources that make up the platform used for running all the jobs.

## Architecture diagram

## Getting started

### AWS deployment

To create S3 bucket backend:

```sh
export ENV="dev"
export REGION="us-east-1"
export AWS_PROFILE="default"
export PROJECT_NAME="gbto"
export TERRAFORM_BUCKET_NAME="${PROJECT_NAME}-tf-states-${ENV}"

/bin/bash create-tf-state-bucket.sh -e $ENV -r $REGION -p $AWS_PROFILE -b $TERRAFORM_BUCKET_NAME
```

To initialize the terraform project with S3 backend:

```sh
terraform init \
        -backend-config="bucket=${TERRAFORM_BUCKET_NAME}" \
        -backend-config="key=${PROJECT_NAME}-platform-${ENV}.tfstate" \
        -backend-config="region=$REGION"
```

To create the deployment plan and apply it:

```sh
# format the terraform code
terraform fmt

# plan the deployment of resources
terraform plan

# deploy the resources to AWS
terraform apply

# destroy the existing AWS resources
terraform destroy
```

To destroy the infrastructure, you need to delete all files in the bucket first:

```sh
AWS_PROFILE="default"
BUCKET_NAME=$(terraform output -json | jq -r .s3_bucket_name.value)
aws s3 rm s3://${BUCKET_NAME} --recursive --profile $AWS_PROFILE
```

We can then destroy all infrastructure via terraform destroy, which will again take around 20-30 minutes.

### DAGS S3 synchronisation

As indicated in [AWS documentation](https://aws.amazon.com/blogs/opensource/deploying-to-amazon-managed-workflows-for-apache-airflow-with-ci-cd-tools/), to set up the GitHub Actions to automatically sync our dags folder containing the actual DAG code to S3, we can use the `access_key_id`, `secret_access_key`, `region` and `s3_bucket_name` from the terraform output. We add those values as Secrets to the repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_S3_BUCKET`
