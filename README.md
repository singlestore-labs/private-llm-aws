# Private LLM on AWS

In this repository you'll find the necessary documentation and code to properly deploy a Private LLM on top of AWS that is backed by SingleStoreDB. This LLM is fully capable Retrieval Augmented Generation (RAG) and can be fed custom business context using SingleStoreDB's Pipeline functions. 

The basic process that this Terraform module uses is to deploy models using SageMaker, front them with FastAPI, and store all interactions inside of SingleStoreDB. SingleStoreDB will also provide additional context to the application that you're working with to ensure that you're able to build your business logic into the application.

This module optionally deploys Kai Shoes, our _fake_ eCommerce store, with a ChatBot that allows you to demonstrate the power of having a contextual LLM that runs on a private network (inside your VPC).

We plan to continue to build out functionality in this module over time, please check out [CONTRIBUTING.md](./CONTRIBUTING.md) to learn more about how you can help us build in more functionality!

## Notes

User

the user you're deploying this with needs:

- SageMaker createDomain

``` JSON
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": "sagemaker:CreateDomain",
			"Resource": "*"
		},
		{
            "Action": [
                "sagemaker:ListTags"
            ],
            "Effect": "Allow",
            "Resource": "*"
         }
	]
}
```

## Known Issues

- [#1]() `terraform destroy [...]` doesn't destroy subnet without you deleting EFS shares and the VPC manually
