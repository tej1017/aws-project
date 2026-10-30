variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "student_name" {
  type        = string
  description = "Your name (used in the Student tag)"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your current public IPv4 as /32, e.g. 203.0.113.7/32 (curl -s https://checkip.amazonaws.com)"
}

variable "public_key_path" {
  type        = string
  default     = "~/.ssh/ewb-lab.pem.pub"
  description = "Public half of your local key. The private key never leaves your laptop."
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "enable_peering" {
  type        = bool
  default     = false
  description = "false = baseline (no peering). true = create peering + routes."
}
