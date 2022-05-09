#!/bin/bash
# Authenticates to an AWS ECR container registry and create a repository
# Get account id with aws sts get-caller-identity --profile sbx-mfa
# Syntax: ecr-create-repository.sh [aws region] [aws account id] [repository name]
# Example: /bin/bash ecr-buil-push.sh $REGION $AWS_ACCOUNT_ID $REPOSITORY_NAME $PROFILE

REGION=$1
AWS_ACCOUNT_ID=$2
REPOSITORY_NAME=$3
PROFILE=$4

if [[ -z $REGION ]] ||  [[ -z $AWS_ACCOUNT_ID ]] ||  [[ -z $REPOSITORY_NAME ]] || [[ -z $PROFILE ]];
then
    echo "The REGION, AWS_ACCOUNT_ID, REPOSITORY_NAME or PROFILE environment variables "
    echo "should be set in order to run this script. Declare it and try again."
fi

DEFAULT_POLICY=$(cat <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
)

# Authenticate
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Create the ECR repository
aws ecr create-repository --registry-id $AWS_ACCOUNT_ID --repository-name $REPOSITORY_NAME --region $REGION --profile $PROFILE

# Set the policy to allow pushing images
aws ecr set-repository-policy \
    --registry-id $AWS_ACCOUNT_ID \
    --repository-name $REPOSITORY_NAME \
    --policy-text $DEFAULT_POLICY \
    --profile $PROFILE \
    --region $REGION


# Build and push the image to ECR
REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME
IMAGE_NAME=$REPOSITORY_NAME
IMAGE_TAG='latest'
IMAGE_TMSTP=$(date +%s)

if [[ $1 = 'arm64' ]];
then
    docker build -t $REPOSITORY_URI:$IMAGE_TAG .
    docker build -t $REPOSITORY_URI:$IMAGE_TMSTP
else
    docker build --platform linux/amd64 -f ./Dockerfile -t $REPOSITORY_URI:$IMAGE_TAG .
    docker build --platform linux/amd64 -f ./Dockerfile -t $REPOSITORY_URI:$IMAGE_TMSTP .
fi

docker push $REPOSITORY_URI --all-tags
