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
    name = "terraform-inferences-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
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
          Resource = "*"
        }
      ]
    })

  }
}

locals {
  role_arn = aws_iam_role.pllm-create-sagemaker-execution-role.arn
}

### SageMaker Create Domain

resource "aws_sagemaker_domain" "sagemaker_domain" {
  domain_name = format("%s-%s",var.sagemaker.domain_name,random_string.resource_id.result)
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

## New hotness

### SageMaker Model

resource "aws_sagemaker_model" "model_from_hub" {
  name               = format("%s-%s","pllm-model",random_string.resource_id.result)
  execution_role_arn = local.role_arn
  tags               = {
    Name             = format("%s-%s","pllm-model",random_string.resource_id.result)
  }

  primary_container {
    image = "763104351884.dkr.ecr.us-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.0.1-tgi0.9.3-gpu-py39-cu118-ubuntu20.04"
    environment = {
      HF_TASK           = var.hf_task
      HF_MODEL_ID       = var.hf_model_id
      HF_API_TOKEN      = var.hf_api_token
      HF_MODEL_REVISION = var.hf_model_revision
      SM_NUM_GPUS       = 4
    }
  }
}

### SageMaker Endpoint Configuration

resource "aws_sagemaker_endpoint_configuration" "pllm-endpoint-config" {
  name  = format("%s-%s","pllm-endpoint-config",random_string.resource_id.result)
  tags  = {
    Name = format("%s-%s","pllm-endpoint-config",random_string.resource_id.result)
  }


  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.model_from_hub.name
    instance_type          = var.instance_type
    initial_instance_count = 1
  }
}

### SageMaker Endpoint

resource "aws_sagemaker_endpoint" "pllm-endpoint" {
  name = format("%s-%s","pllm-endpoint",random_string.resource_id.result)
  tags = {
    Name = format("%s-%s","pllm-endpoint",random_string.resource_id.result)
  }

  endpoint_config_name = aws_sagemaker_endpoint_configuration.pllm-endpoint-config.name
}