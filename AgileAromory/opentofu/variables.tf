variable "environment" {
  description = "Choose between dev and prod"
  type        = string
  default     = "dev"
}

variable "provider" {
  description = "Choose libvirt or vcenter"
  type        = string
  default     = "libvirt"
}
