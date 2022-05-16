#!/bin/bash
# Maintainer: Quentin Gaborit, <gibboneto@gmail.com>
# This script creates a bucket to store terraform states
# Syntax: create-tf-state-bucket.sh [-e target folder] [-r region] [-p aws profile] [-b terraform bucket]

# Declare default arguments
ENV="dev"
AWS_REGION="us-east-1"
AWS_PROFILE="default"
AWS_BUCKET="gbto-tf-states-${ENV}"

# Parse user arguments
while getopts e:r:p:b: option; do
    case "${option}" in
    e) ENV=${OPTARG} ;;
    r) AWS_REGION=${OPTARG} ;;
    p) AWS_PROFILE=${OPTARG} ;;
    b) AWS_BUCKET=${OPTARG} ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
    esac
done

# Warn for missing parameters
if [[ -z $ENV ]] || [[ -z $AWS_REGION ]] || [[ -z $AWS_PROFILE ]] || [[ -z $AWS_BUCKET ]]; then
    echo "ERROR: Some required parameters are missing. Verify that you've passed correctly an ENV, AWS_REGION, PROFILE and BUCKET. Exiting script."
    exit 1
elif aws s3api head-bucket --bucket "$AWS_BUCKET" --region $AWS_REGION --profile $AWS_PROFILE 2>/dev/null; then
    echo "The bucket already exists, re-creating it would erase its content. Exiting script."
    exit 1
else
    # Printing passed parameters
    echo "Initializing creation of the bucket with the following parameters:"
    echo "environment: $ENV"
    echo "aws region: $AWS_REGION"
    echo "aws profile: $AWS_PROFILE"
    echo "terraform bucket name: $AWS_BUCKET"

    # Create bucket
    if [[ $AWS_REGION == "us-east-1" ]]; then
        aws s3api create-bucket \
            --bucket $AWS_BUCKET \
            --profile $AWS_PROFILE \
            --region $AWS_REGION \
            --no-cli-pager 2>&1
    else
        aws s3api create-bucket \
            --bucket $AWS_BUCKET \
            --region $AWS_REGION \
            --create-bucket-configuration LocationConstraint=$AWS_REGION \
            --profile $AWS_PROFILE \
            --no-cli-pager 2>&1
    fi
    # Make it not public
    echo "Making $AWS_BUCKET private"
    aws s3api put-public-access-block \
        --bucket $AWS_BUCKET \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile $AWS_PROFILE

    # Enable versioning
    echo "Enabling $AWS_BUCKET versioning"
    aws s3api put-bucket-versioning \
        --bucket $AWS_BUCKET \
        --versioning-configuration Status=Enabled \
        --profile $AWS_PROFILE

    echo "Created $AWS_BUCKET bucket succesfully in $AWS_REGION"
fi
