# EKS / RDS secured deployment

This repository contains terraform code to deploy an AWS environment with:

- A VPC containing 8 subnets (4 privates, 4 publics)
- A PostGre RDS database
- A cluster EKS with 2 workers (1 private, 1 public)

This infrastructure addresses the need of an application that would have a front-end that interacts with internet which also accesses a back-end where stored sensitive data requires as much protection as possible. In that schema, the front-end servers would be in the public subnets, while all databases and back-end services would be in the private subnets.

It tries to apply a security strategy that involves several level of protection, starting with a subnet level security strategy. From a network perspective, we will define network access control lists with inbound and outbound rules that will set different traffic permissions for the different area of the VPC.

Additionally to the network securisation strategy, we will implement a control of inbound/outbound traffic at instances level (dbs, compute instances…) by defining security groups that will act as instance level virtual firewalls. Similarly, we will define for the security groups our instances will be attached to ingress and egress rules with protocols, ip and port ranges conditions.

Finally, we want to create a mecanism whereby we tie AWS IAM roles and security groups to kubernetes service accounts so that we have a Pod level security policy inside our kubernetes cluster. In particular, we will create security group that allows inbound traffic to RDS for pods using a specific service account.

## 1. Access control lists

The network is divided in 4 areas: eks internal, eks external, rds internal, rds external. For each of these areas are defined access control lists:

- EKS internal: Allows both inbound and outbound ttraffic from/to any IP on any port.
- EKS external: Allows both inbound and outbound traffic from/to any IP on any port.
- RDS internal: Limits both inbound and outbound traffic only to the VPC's EKS private subnets on port 5432 and RDS public/private subnets on any port.
- RDS external: Limits inbound traffic to the VPC's RDS private and public subnets on any port only, and outbound traffic to any ip and any port.

## 2. Security groups

We define several security groups that controls inbound and outbound rules on the different resources of the environment. That includes:

1. postgresql: Inbound from RDS public subnets, RDS private subnets and security group rds-access-from-pod on port 5432. Outbound to RDS public subnets on port 5432, RDS private subnets on any ports, as well as the rds-access-from-pod security group on ports 1025-65535.

2. eks-cluster-ControlPlane: Allow communication between the control plane and worker node groups

3. eks-cluster-DataPlane: Allow unmanaged nodes to communicate with the control plane.

4. rds-access-from-pod: Allow inbound traffic to pod with TCP and UDP on port 53 and all outbound traffic.

## 3. K8s security group policy

To be completed.

## Create a metabase user in RDS

As explained above, to access RDS from an EKS pod, it'll be required to use a specific service account, that will be tied to an IAM role (i.e. security group) through a K8s security group policy. This implies that we need to create a Postgre user.

For this we will need to login the psql which is not accessible from outside the VPC and manually create the user. Ideally, we should set-up a [bastion host](https://registry.terraform.io/modules/Guimove/bastion/aws/latest) for this kind of operation. For now, we will simply add a whitelisting network ingress rule to enable connection from a local machine to the RDS instance safeguarded behind the network ACL we've defined through terraform.
In particular, one would need to

For this, one would need to create access control list inbound and outbound rules that allows traffic from a specific IP to both the internal and external RDS zone (traffic comes throught the internet gateway, then is routed to the public subnets that are ).

Then, we can login PSQL with:

```sh
#!/bin/bash
cd ../terraform-plan/
USER=$(terraform output rds-username)
PASS=$(terraform output rds-password)
HOST=$(terraform output public-rds-endpoint)

psql \
   --host=<HOST> \
   --port=<PORT> \
   --username=<USER> \
   --password \
   --dbname="postgres"
```

And finally create the user with:
```sh
CREATE USER metabase;
GRANT rds_iam TO metabase;
CREATE DATABASE metabase;
GRANT ALL ON DATABASE metabase TO metabase;
```

## Run the kubernetes manifests

```sh
#!/bin/zsh
ROOT=$PWD

# Generate DB auth token
cd ./terraform-plan/

REGION="eu-west-1"
METABASE_PWD=$(aws rds generate-db-auth-token --hostname $(terraform output private-rds-endpoint) --port 5432 --username metabase --region $REGION)
METABASE_PWD=$(echo -n $METABASE_PWD | base64 -b 0 )

SG_RDS_ACCESS=$(terraform output sg-rds-access)
SG_EKS_CLUSTER=$(terraform output sg-eks-cluster)
RDS_ACCESS_ROLE_ARN=$(terraform output rds-access-role-arn)
PRIVATE_RDS_ENDPOINT=$(terraform output private-rds-endpoint)

# Replace all the templates from the k8s manifest
cd $ROOT/k8s-manifests/
sed -i'.backup' -e "s/<MB_DB_PASS>/$METABASE_PWD/g" database-secret.yaml
sed -i'.backup' -e "s/<POD_SECURITY_GROUP_ID>/$SG_RDS_ACCESS/g" -e "s/<EKS_CLUSTER_SECURITY_GROUP_ID>/$SG_EKS_CLUSTER/g" security-group-policy.yaml
sed -i'.backup' -e "s,<RDS_ACCESS_ROLE_ARN>,$RDS_ACCESS_ROLE_ARN,g" service-account.yaml
sed -i'.backup' -e "s/<MB_DB_HOST>/$PRIVATE_RDS_ENDPOINT/g" deployment.yaml

# Run the manifests
kubectl create namespace metabase
kubectl config set-context --current --namespace=metabase

kubectl apply -f database-secret.yaml
kubectl apply -f security-group-policy.yaml
kubectl apply -f service-account.yaml
kubectl apply -f deployment.yaml
```

## Set-up instructions

- Create an [AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) and [install the CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
- Install [docker](https://docs.docker.com/desktop/), [kubernetes](https://kubernetes.io/docs/setup/) and [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Install [PostgreSQL](https://www.postgresql.org/download/)
