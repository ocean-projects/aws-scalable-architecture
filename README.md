# AWS Scalable Architecture

This project demonstrates how to set up a scalable architecture on AWS using Terraform. It includes components like VPC, EC2, Load Balancers, and Auto Scaling Groups and cross regional databases to ensure high availability and performance.


## Prerequisites

- An AWS account
- Terraform installed on your machine
- AWS CLI configured with appropriate permissions


## Files included:

### variables.tf

- Defines input variables for the configuration, including regions, availability zones, CIDR blocks, and database password.

### main.tf

Provider

- Defines AWS as the provider for Terraform.
- Configures two separate AWS provider instances for two different regions using aliases (`region_1` and `region_2`).

VPC

- Creates two VPCs in different regions with specified CIDR blocks.
- Creates two public subnets in Region 1, enabling public IP assignment on launch.
- Creates two private subnets in Region 2, without public IP assignment.
- Creates internet gateways for both VPCs, allowing internet access to resources within the public subnets.
- Defines route tables for both regions, directing outbound traffic (0.0.0.0/0) through the corresponding internet gateways.
- Associates the public subnets in both regions with their respective route tables.

EC2

- Retrieves the latest Amazon Linux AMI for use in launching EC2 instances.
- Configures a security group for the web server, allowing HTTP and SSH traffic.

Security Groups

- Creates a launch template for the web server instances, specifying the AMI, instance type, key name, and associated security group.

ALB

- Creates an Application Load Balancer for distributing incoming traffic to the web server instances.

ASG

- Sets up an Auto Scaling Group with specified capacity settings, linking it to the launch template and ensuring it uses the Load Balancer for health checks.

RDS - MySQL

- Creates an RDS MySQL database instance in Region 2 with specified configurations.
- Configures a subnet group for the RDS instance to be launched in the private subnets of Region 2.
- Creates a read replica of the main RDS instance for improved availability and read performance.