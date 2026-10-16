variable "location" {
  description = "Hetzner Object Storage region."
  type        = string
  default     = "fsn1"
  validation {
    condition     = contains(["fsn1", "nbg1", "hel1"], var.location)
    error_message = "Choose fsn1, nbg1, or hel1."
  }
}
variable "name_prefix" {
  description = "Unique prefix for these example bucket names. Include a trailing hyphen."
  type        = string
}
