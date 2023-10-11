terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
    singlestoredb = {
      source = "singlestore-labs/singlestoredb"
      version = "0.1.0-alpha.5"
    }
  }
}

# Configure the AWS Provider
# Uses IAM credentials requested at run time
provider "aws" {
  region = "${var.aws.AWS_REGION}"
  access_key = "${var.aws.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.aws.AWS_SECRET_ACCESS_KEY}"
}

## [IAM] Policy Documents

data "aws_iam_policy_document" "s3_ls_policy_data" {
  statement {
    actions = [
      "s3:ListAllMyBuckets"
    ]
resources = [
      "arn:aws:s3:::*"
    ]
  }
}

data "aws_iam_policy_document" "s3_ls_assume_role_data" {
  statement {
    actions = ["sts:AssumeRole"]
principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}


## [IAM] Private LLM Group

### Create the IAM Policy using role above

resource "aws_iam_role_policy" "s3_ls_policy" {
  name   = "s3_ls_iam_policy"
  policy = data.aws_iam_policy_document.s3_ls_policy_data.json
  role   = aws_iam_role.s3_ls_role.id
}

resource "aws_iam_role" "s3_ls_role" {
  name               = "s3_ls_iam_role"
  description        = "This role allows for all S3 buckets to be listed."
  assume_role_policy = data.aws_iam_policy_document.s3_ls_assume_role_data.json
}


### Create IAM Group for Users

resource "aws_iam_group" "pllm-create-group" {
  name = "${var.pllm-group.group_name}"
  path = "/"
}


## [IAM] API USER

### Create IAM User for API to LLM comms

resource "aws_iam_user" "pllm-create-api-user" {
  name = "${var.api.user_name}"
  path = "/"
}

### Add IAM User to Group from above

resource "aws_iam_user_group_membership" "pllm-create-api-user-group-membership" {
  groups = [
    aws_iam_group.pllm-create-group.name
  ]
  user = aws_iam_user.pllm-create-api-user.name
  depends_on = [
    aws_iam_group.pllm-create-group,
    aws_iam_user.pllm-create-api-user
  ]
}

### Create IAM Access Key for API to LLM comms
resource "aws_iam_access_key" "pllm-create-api-user-apikey" {
  user = aws_iam_user.pllm-create-api-user.name
  depends_on = [
    aws_iam_user.pllm-create-api-user
  ]
  # FIXME: Store the access key ID and secret in variables for later use
}

### Create IAM Role for API to LLM comms

resource "aws_iam_role" "pllm-create-api-role" {
  name = "${var.api.role_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


### Attach IAM Role Policies for API to LLM comms to role from above

#### - Attach IAM Role Policy for S3 ReadOnly to role from above

resource "aws_iam_role_policy_attachment" "pllm-attach-api-user-S3RO" {
  role       = aws_iam_role.pllm-create-api-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

#### - SageMaker RO

resource "aws_iam_role_policy_attachment" "pllm-attach-api-user-SageMakerRO" {
  role       = aws_iam_role.pllm-create-api-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerReadOnly"
}


## [IAM] LLM Deployment User

### Create IAM User for LLM deployment

resource "aws_iam_user" "pllm-create-deploy-user" {
  name = "${var.llm-deployer.user_name}"
  path = "/"
}

### Add IAM User to Group from above

resource "aws_iam_user_group_membership" "pllm-create-deploy-user-group-membership" {
  groups = [
    aws_iam_group.pllm-create-group.name
  ]
  user = aws_iam_user.pllm-create-deploy-user.name

  depends_on = [
    aws_iam_group.pllm-create-group,
    aws_iam_user.pllm-create-deploy-user
  ]
}

### Create IAM Access Key for LLM deployment

resource "aws_iam_access_key" "pllm-create-deploy-user-apikey" {
  user = aws_iam_user.pllm-create-deploy-user.name
  depends_on = [
    aws_iam_user.pllm-create-deploy-user
  ]
}

### Create IAM Role for LLM deployment

resource "aws_iam_role" "pllm-create-deploy-role" {
  name = "${var.llm-deployer.role_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

### Attach IAM Role Policies for LLM Deployer to role from above

resource "aws_iam_role_policy_attachment" "pllm-attach-deploy-user-S3RO" {
  role       = aws_iam_role.pllm-create-deploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

#### Attach IAM Role Policy SageMaker Full to role from above

resource "aws_iam_role_policy_attachment" "pllm-attach-deploy-user-SageMakerFull" {
  role       = aws_iam_role.pllm-create-deploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

#### Attach IAM Role Policy SageMaker Canvas Full to role from above

resource "aws_iam_role_policy_attachment" "pllm-attach-deploy-user-SageMakerCanvasFull" {
  role       = aws_iam_role.pllm-create-deploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerCanvasFullAccess"
}

#### Attach IAM Role Policy AppRunner Full to role from above

resource "aws_iam_role_policy_attachment" "pllm-attach-deploy-user-AppRunnerFull" {
  role       = aws_iam_role.pllm-create-deploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppRunnerFullAccess"
}

#### Attach IAM Role Policy SageMaker Forecast Access to role from above

resource "aws_iam_role_policy_attachment" "pllm-attach-deploy-user-SageMakerForecastAccess" {
  role       = aws_iam_role.pllm-create-deploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonForecastFullAccess"
}

## Create VPC and other Network Resources

### Create VPC
resource "aws_vpc" "pllm-create-vpc" {
  cidr_block = "${var.vpc.cidr_block}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.vpc.vpc_name}"
  }
}

### Create Subnet inside of VPC
resource "aws_subnet" "pllm-create-subnet" {
  vpc_id = aws_vpc.pllm-create-vpc.id
  cidr_block = "${var.vpc.subnet_cidr_block}"
  tags = {
    Name = "${var.vpc.subnet_name}"
  }
}