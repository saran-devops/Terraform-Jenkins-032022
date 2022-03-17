variable "bucket_prefix" {
  type        = string
  description = "(required since we are not using 'bucket') Creates a unique bucket name beginning with the specified prefix"
  default     = "terraformbucket-"
}

variable "tags" {
  type        = map(any)
  description = "bucket tag"
  default = {
    environment = "DEV"
    terraform   = "true"
  }
}

variable "ingressrules" {
  type    = list(number)
  default = [80, 443, 22]
}
