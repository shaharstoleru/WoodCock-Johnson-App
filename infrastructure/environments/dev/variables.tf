variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "diagnosis-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}