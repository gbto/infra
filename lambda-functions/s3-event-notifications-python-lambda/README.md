# Example of lambda/s3/s3-event-notifications deployment with terraform

This folder contains terraform files developed for learning purposes.
In the spirit of an event driven
Currently, it includes terraform code that creates the AWS resources necessary to create a Lambda function processing messages of a S3 bucket. The Lambda is triggered by a s3 event notifications on object creation with no filtering.
[S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html) are for events that are specific to S3 buckets. S3 Events Notifications can publish events for:

- New object created
- Object removal
- Restore object
- Reduced Redundancy Storage (RRS) object lost events
- Replication events

In addition to S3, event notifications and Lambda instances, should be created IAM role and policies to enable the Lambda function to:

1. access AWS resources and services (cf. lambda's [execution role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html))
2. write messages to S3 bucket (cf. [permissions to S3 buckets](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_s3_rw-bucket.html))
3. send logs to Amazon CloudWatch (cf. [CloudWatch logs](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html))

## Set-up instructions

In order to run the code, you need to configure AWS CLI and set-up a profile. The name of the profile needs to be specified in the variables.tf to be accessed by terraform. All the variables necessary to parameterize the deployment of all the ressources of this project are configurable in the variables.tf file. This includes the aws profile name as used in any ``aws``` cli command, the name of the bucket to create the name of the environment used when tagging ressources.

For triggering the lambda function, we should first ensure the 2 buckets declared in the variables.tf files exists in the same AWS account and same region, then add files to these 2 folders and finally observe whether the lambda behaves correctly through CloudWatch logs and Lambda Metrics. A sample of the file can be found in this repository, as `test-file.gz`.

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
        -backend-config="key=${PROJECT_NAME}-lambda-s3-events-python-${ENV}.tfstate" \
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
