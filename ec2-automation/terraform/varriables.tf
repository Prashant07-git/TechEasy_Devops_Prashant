variable "stage" {
  description = "Deployment stage: dev or prod"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS Key Pair"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}


variable "security_group_id" {
  description = "Optional existing Security Group ID to use"
  type        = string
  default     = ""
}
