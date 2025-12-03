variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "domain_name" {
  description = "OpenSearch domain name"
  type        = string
  default     = "k8s-logs-demo"
}

variable "master_user_name" {
  description = "Master username for OpenSearch"
  type        = string
  default     = "admin"
}

variable "master_user_password" {
  description = "Master user password for OpenSearch"
  type        = string
  sensitive   = true
}

variable "allowed_ip_cidr" {
  description = "Your public IP CIDR allowed to access OpenSearch (e.g. 1.2.3.4/32)"
  type        = string
}

variable "env" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}