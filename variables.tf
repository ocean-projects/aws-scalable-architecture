# variables.tf

variable "db_password" {
  description = "Password for the MySQL database"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH access"
  type        = string
}

variable "region_1" {
  description = "The first AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "region_2" {
  description = "The second AWS region where resources will be created"
  type        = string
  default     = "us-west-1"
}

variable "az_1" {
  description = "List of availability zones for the first region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "az_2" {
  description = "List of availability zones for the second region"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1c"]
}

variable "az_1_cidrs" {
  description = "CIDR blocks for the subnets in region 1"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "az_2_cidrs" {
  description = "CIDR blocks for the subnets in region 2"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}
