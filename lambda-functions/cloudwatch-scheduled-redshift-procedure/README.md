# SUMMARY

This folder contains code that deploy a Lambda function containerized in an image stored in ECR. The function will:

- Retrieve credentials from Secrets Manager
- Use it to connect to redshift
- Create a dummy table
- Insert data in the table
- Select the data newly created in memory
- Write it to an S3 bucket

# Set-up instructions

In order to run the code, you need to configure AWS CLI and set-up a profile. The name of the profile needs to be specified in the variables.tf to be accessed by terraform. All the variables necessary to parameterize the deployment of all the ressources of this project are configurable in the variables.tf file. This includes the aws profile name as used in any ``aws``` cli command, the name of the bucket to create the name of the environment used when tagging ressources.

Because the Lambda Function is containerized in an image, before deploying the terraform resources, we need to first create the ECR repository with an appropriate IAM policy, then build and push the image to the repository (nb: Since in the terraform code we define the lambda name with `"${var.project_name}-${var.function_name}-${var.env_name}"`, we should name the repository accordingly). This can be done with the following piece of code:

```
REGION='region'
AWS_ACCOUNT_ID=<aws_account_id>
REPOSITORY_NAME='<project>-<function>-<environment>'
PROFILE=<aws_config_profile>

/bin/bash ecr-build-push.sh $REGION $AWS_ACCOUNT_ID $REPOSITORY_NAME $PROFILE
```

# Credentials:

Finally, the Docker image will use credentials that are created through terraform and stored in AWS SecretsManager. To automate the creation, the credentials content should be added to a terraform.tfvars file, stored in the root of the folder. This file should include:

```
redshift_config =  {
        "host": "host",
        "port": "5439",
        "database": "database",
        "username": "user",
        "password": "password"
    }
```

During the Terraform apply, these credentials will be created as well as the permissions granted to the Lambda so that our script can access it.

# Deploy the resources

To initialize the terraform project with S3 backend:

```
export ENV="dev"
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"
export PROJECT_NAME="gbto"
export TERRAFORM_BUCKET_NAME="${PROJECT_NAME}-tf-states-${ENV}"

terraform init \
        -backend-config="bucket=${TERRAFORM_BUCKET_NAME}" \
        -backend-config="key=${PROJECT_NAME}-lambda-cloudwatch-redshift-procedure-${ENV}.tfstate" \
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

To destroy the infrastructure, you need to delete all files in the bucket first:

```
AWS_PROFILE="default"
BUCKET_NAME=$(terraform output -json | jq -r .s3_bucket_name.value)
aws s3 rm s3://${BUCKET_NAME} --recursive --profile $AWS_PROFILE
```
