# Declare vars

variable "project" {
  type        = string
  description = "Name of the project."
}

variable "location" {
  type        = string
  description = "Region where project will be deployed."
  default     = "eu-west"
}