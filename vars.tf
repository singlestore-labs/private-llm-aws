variable api_image_uri {
    description = "The API between SageMaker, Your Apps, and SingleStore"
    type = string
    default = "public.ecr.aws/n7b1f4b4/private_llm_fastapi_server:latest"
}

variable "naming_prefix" {
    description = "Naming Prefix - ie pllm"
    type = string
    default = "pllm"
}

variable "hf_task" {
    description = "HuggingFace Task - ie text-generation"
    type = string
    default = "text-generation"
}

variable "hf_model_id" {
    description = "HuggingFace Model ID - ie TheBloke/Llama-2-7B-GGUF"
    type = string
    default = "meta-llama/Llama-2-7b-chat-hf"
}

variable "hf_api_token" {
    description = "HuggingFace API Token"
    type = string
    default = null
}

variable "hf_model_revision" {
    description = "HuggingFace Model Revision - allows you to pin to a specific version"
    type = string
    default = null
}

variable "instance_type" {
    description = "Instance Type - ie ml.g4dn.xlarge"
    type = string
    default = "ml.g4dn.12xlarge"
}

variable "create_db" {
    description = "Create a SingleStore DB, defaults to false, expecting you might already have a database in place."
    type = bool
    default = false
}

variable "init_db" {
    description = "Initialize the SingleStore DB with the Proper Schema, defaults to false, expecting you might already have a database in place."
    type = bool
    default = false
}

variable "aws" {
    type = object({
        AWS_ACCESS_KEY_ID = string
        AWS_SECRET_ACCESS_KEY = string
        AWS_REGION = string
        AWS_ACCOUNT_ID = string
    })
    default = {
            AWS_ACCESS_KEY_ID = ""
            AWS_SECRET_ACCESS_KEY = ""
            AWS_REGION = "us-west-2"
            AWS_ACCOUNT_ID = ""
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
            repo_name = string
            service_name = string
        }
    )
    default = {
            user_name = "pllm-api-user"
            role_name = "pllm-api-role"
            repo_name = "pllm-api"
            service_name = "pllm-api-svc"
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

variable "s2_db_host" {
    type = string
}

variable "s2_db_name" {
    type = string
}

variable "s2_db_user" {
    type = string
}

variable "s2_db_pass" {
    type = string
}
