# Terraform AWS Infrastructure

This Terraform configuration sets up an AWS infrastructure including a VPC, subnets, an Application Load Balancer, security groups, and an ECS service for deploying a containerized application.

## Prerequisites

Before you begin, make sure you have the following prerequisites:

1. [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
2. AWS Access Key ID and Secret Access Key. Ensure that these credentials have the necessary permissions to create the resources defined in this configuration.

## Installation

1. Clone this Git repository to your local machine:

   **git clone https://github.com/Logesh-Devops/Terraform.git**
   **cd Terraform**


2. Initialize Terraform and download the necessary plugins:

    **terraform init**


3. Plan the infrastructure to see what changes will be applied:

    **terraform plan**


4. Apply the infrastructure setup:

    **terraform apply**


Terraform will create the specified AWS resources based on your configuration.

Running and Managing

You can run and manage your infrastructure using Terraform commands such as terraform plan, terraform apply, and terraform destroy. For more details on Terraform commands, refer to the Terraform Documentation.

Clean Up

5. When you no longer need the infrastructure, you can clean up the resources by running:

    **terraform destroy**

This will remove all the AWS resources created by this configuration.