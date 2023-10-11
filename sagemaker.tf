# Setup SageMaker 

### SageMaker IAM Policy Document

data "aws_iam_policy_document" "pllm-sagemaker-execution-policy" {
  statement {
    actions = [
        "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

### SageMaker IAM Execution Role

resource "aws_iam_role" "pllm-create-sagemaker-execution-role" {
  name               = "${var.sagemaker.exec_role_name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.pllm-sagemaker-execution-policy.json
  inline_policy {
    name = "pllm-sagemaker-ecr-execution-policy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams",
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
  }
}

### SageMaker Create Domain

resource "aws_sagemaker_domain" "sagemaker_domain" {
  domain_name = "${var.sagemaker.domain_name}"
  auth_mode   = "IAM"
  vpc_id      = aws_vpc.pllm-create-vpc.id
  subnet_ids  = [
    aws_subnet.pllm-create-subnet.id
  ]
  default_user_settings {
    execution_role = aws_iam_role.pllm-create-sagemaker-execution-role.arn
  }
  depends_on  = [
    aws_vpc.pllm-create-vpc
  ]
}

### Deploy embedding model from HuggingFace to SageMaker

module "sagemaker-huggingface" {
  source                   = "philschmid/sagemaker-huggingface/aws"
  version                  = "0.8.0"
  name_prefix              = "sentence-transformers" # change to a variable with embeddings
  pytorch_version          = "1.9.1"
  transformers_version     = "4.12.3"
  instance_type            = "ml.g4dn.xlarge"
  instance_count           = 1 # default is 1
#   hf_api_token             = var.huggingface_key
  hf_model_id              = "mistralai/Mistral-7B-v0.1"
  hf_task                  = "text-generation"
  sagemaker_execution_role = aws_iam_role.pllm-create-sagemaker-execution-role.name
  depends_on               = [
    aws_iam_role.pllm-create-sagemaker-execution-role,
    aws_sagemaker_domain.sagemaker_domain
  ]
}