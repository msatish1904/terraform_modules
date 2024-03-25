variable "region"{
  description = "Location of S3"
  type        = string
  default     = "us-east-1"
}

variable "s3_config" {
  description = "details of the s3 configuration"
  type = map(object({
    bucket_versioning_configuration_status = string
#    bucket_policy                          = string
  }))
  
}


variable "tags" {
  description = "Any tags that should be present on the resources"
  type        = map(string)
  default     = {}
}

/*
variable "restrict_public_buckets" {
  description = "to block public access to the bucket or not"
  type = bool
  default = false
}
