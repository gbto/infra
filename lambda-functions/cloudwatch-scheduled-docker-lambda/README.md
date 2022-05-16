# Example of lambda/cloudwatch/s3 deployment with terraform

This folder contains terraform files developed for learning purposes.

Currently, it includes terraform code that creates the AWS resources necessary to create a Lambda function sending messages to a S3 bucket. The Lambda is triggered by a scheduled CloudWatch event configured to a 1 minute frequency and will send logs to CloudWatch console.

Rather than running a zipped Python script, the lambda is containerized in an imaged, pushed to AWS Elastic Container Registry.

In addition to S3, CloudWatch and Lambda instances, should be created IAM role and policies to enable the Lambda function to:

1. access AWS resources and services (cf. lambda's [execution role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html))
2. write messages to S3 bucket (cf. [permissions to S3 buckets](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_s3_rw-bucket.html))
3. send logs to Amazon CloudWatch (cf. [CloudWatch logs](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html))
4. access the ECR where is stored the Lambda function image

## Set-up instructions

In order to run the code, you need to configure AWS CLI and set-up a profile. The name of the profile needs to be specified in the variables.tf to be accessed by terraform. All the variables necessary to parameterize the deployment of all the ressources of this project are configurable in the variables.tf file. This includes the aws profile name as used in any ``aws``` cli command, the name of the bucket to create the name of the environment used when tagging ressources.

Because the Lambda Function is containerized in an image, before deploying the terraform resources, we need to first create the ECR repository with an appropriate IAM policy, then build and push the image to the repository (nb: Since in the terraform code we define the lambda name with `"${var.project_name}-${var.function_name}-${var.env_name}"`, we should name the repository accordingly). This can be done with the following piece of code:

```sh
AWS_REGION='region'
AWS_ACCOUNT_ID=<aws_account_id>
REPOSITORY_NAME='<project>-<function>-<environment>'
AWS_PROFILE=<aws_config_profile>

/bin/bash ecr-build-push.sh $AWS_REGION $AWS_ACCOUNT_ID $REPOSITORY_NAME $AWS_PROFILE
```

## Deploy the resources

To initialize the terraform project with S3 backend:

```sh
export ENV="dev"
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
export PROJECT_NAME="gbto"
export TERRAFORM_BUCKET_NAME="${PROJECT_NAME}-tf-states-${ENV}"

terraform init \
        -backend-config="bucket=${TERRAFORM_BUCKET_NAME}" \
        -backend-config="key=${PROJECT_NAME}-lambda-cloudwatch-docker-${ENV}.tfstate" \
        -backend-config="region=$AWS_REGION"
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
