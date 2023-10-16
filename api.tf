/*
API Module

This module creates the API service, currently running on App Runner, that enables
communication between your applications, the SageMaker endpoint, and the database.

We expect that people will take our [API repo](FIXME) and customize it to their needs.

Ensure that you update the variable `api_image_uri` to point to your own ECR repo.

*/


## Create app runner service with environment variables from aws_iam_access_key.pllm-create-api-user-apikey

resource "aws_apprunner_service" "create-api-service" {
  service_name = format("%s-%s",var.api.service_name,random_string.resource_id.result)

  source_configuration {
    image_repository {
      image_configuration {
        port = "4000"
        runtime_environment_variables = {
            AWS_ACCESS_KEY_ID        = aws_iam_access_key.pllm-create-api-user-apikey.id
            AWS_SECRET_ACCESS_KEY    = aws_iam_access_key.pllm-create-api-user-apikey.secret
            AWS_EXECUTION_ROLE_ARN   = aws_iam_role.pllm-create-sagemaker-execution-role.arn
            MYSQL_HOST               = var.s2_db_host
            MYSQL_PORT               = "3306"
            MYSQL_USER               = var.s2_db_user
            MYSQL_PASSWORD           = var.s2_db_pass
            MYSQL_DATABASE           = var.s2_db_name
            SAGEMAKER_ENDPOINT       = aws_sagemaker_endpoint.pllm-endpoint.name
            SAGEMAKER_ROLE           = aws_iam_role.pllm-create-sagemaker-execution-role.name
            SAGEMAKER_REGION         = var.aws.AWS_REGION
        }
      }
      image_identifier      = var.api_image_uri
      image_repository_type = "ECR_PUBLIC" # Ensure to change this to ECR_PRIVATE if on private ECR repo
    }
    auto_deployments_enabled = false
  }

  tags = {
    Name = format("%s-%s",var.api.service_name,random_string.resource_id.result)
  }

  depends_on = [
    aws_sagemaker_endpoint.pllm-endpoint
  ]
}