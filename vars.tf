variable "aws" {
    type = object({
        AWS_ACCESS_KEY_ID = string
        AWS_SECRET_ACCESS_KEY = string
        AWS_REGION = string
    })
    default = {
            AWS_ACCESS_KEY_ID = ""
            AWS_SECRET_ACCESS_KEY = ""
            AWS_REGION = "us-west-2"
        }
}

variable "pllm-group" {
    type = object(
        {
            group_name = string
            description = string
        }
    )
    default = {
            group_name = "pllm-group"
            description = "Private LLM Group"
        }
}

variable "api" {
    type = object(
        {
            user_name = string
            role_name = string
        }
    )
    default = {
            user_name = "pllm-api-user"
            role_name = "pllm-api-roll"
    }
}

variable "llm-deployer" {
    type = object(
        {
            user_name = string
            role_name = string
        }
    )
    default = {
            user_name = "pllm-deployer"
            role_name = "pllm-deployer-role"
        }
}

variable "vpc" {
    type = object(
        {
            cidr_block = string
            subnet_name = string
            subnet_cidr_block = string
            vpc_name = string
        }
    )
    default = {
            cidr_block = "10.37.37.0/24"
            subnet_name = "private-llm-subnet"
            subnet_cidr_block = "10.37.37.0/24"
            vpc_name = "private-llm-vpc"
    }
}

variable "sagemaker" {
    type = object(
        {
            domain_name = string
            exec_role_name = string
        }
    )
    default = {
            domain_name = "pllm-sagemaker-domain"
            exec_role_name = "pllm-sagemaker-exec-role"
    }
}

# variable "huggingface_key" {
#     type = string
# }